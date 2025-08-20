#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p src/ui/{components,screens,data}
touch src/index.css

# 0) .env.local подсказка (если нужно)
grep -q VITE_API_BASE .env.local 2>/dev/null || echo 'VITE_API_BASE=https://api.fishtrackpro.ru/api' >> .env.local

# 1) API клиент
cat > src/ui/data/api.ts <<'TS'
import axios from "axios";
const API_BASE = import.meta.env.VITE_API_BASE || "/api";
export const api = axios.create({ baseURL: `${API_BASE}/v1`, timeout: 15000 });

export type Media = { id:number; url:string; type?:string; size?:number };
export type MapPoint = { id:number; lat:number; lng:number; title:string; type:"shop"|"slip"|"camp"|"catch"|"spot"; is_highlighted?:boolean; photo?:Media };
export type CatchItem = { id:number; lat:number; lng:number; fish:string; weight?:number; length?:number; style?:string; privacy?:string; created_at?:string; photo?:Media };

export async function health(){ return (await api.get("/health")).data; }
export async function uploadImage(file:File){
  const fd = new FormData(); fd.append("file", file);
  return (await api.post("/upload/image", fd, { headers:{ 'Content-Type':'multipart/form-data' } })).data as Media;
}

export async function fetchMapPoints(params?:{bbox?:string;filter?:string}){
  const { data } = await api.get("/map/points",{ params }); return data.items ?? data;
}
export async function createPoint(payload:Partial<MapPoint>){
  const { data } = await api.post("/map/points", payload); return data as MapPoint;
}

export async function fetchFeedGlobal(){ const { data } = await api.get("/catches"); return data.items ?? []; }
export async function createCatch(payload:Partial<CatchItem>){ const { data } = await api.post("/catches", payload); return data as CatchItem; }
TS

# 2) Виджеты: лоадер и ошибка
cat > src/ui/components/LoadingOverlay.tsx <<'TSX'
import { Backdrop, CircularProgress } from "@mui/material";
export default function LoadingOverlay({open}:{open:boolean}){
  return (
    <Backdrop sx={{ color:"#fff", zIndex: (t)=>t.zIndex.drawer+1 }} open={open}>
      <CircularProgress />
    </Backdrop>
  );
}
TSX

cat > src/ui/components/ErrorAlert.tsx <<'TSX'
import { Alert } from "@mui/material";
export default function ErrorAlert({message}:{message:string}){ return <Alert severity="error" sx={{my:2}}>{message}</Alert>; }
TSX

# 3) Карта с реальными данными + форма добавления точки
cat > src/ui/components/MapView.tsx <<'TSX'
import { useCallback, useEffect, useRef, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { fetchMapPoints, MapPoint } from "../data/api";
import { Box, ToggleButton, ToggleButtonGroup } from "@mui/material";
const icon = L.icon({ iconUrl:"https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl:"https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl:"https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png", iconSize:[25,41], iconAnchor:[12,41] });

function BboxFetcher({onBbox}:{onBbox:(bbox:string)=>void}){
  const map=useMapEvents({ moveend(){ const b=map.getBounds(); const bbox=[b.getWest(),b.getSouth(),b.getEast(),b.getNorth()].join(","); onBbox(bbox);} });
  useEffect(()=>{ const b=map.getBounds(); const bbox=[b.getWest(),b.getSouth(),b.getEast(),b.getNorth()].join(","); onBbox(bbox);},[]);
  return null;
}

export default function MapView(){
  const [points,setPoints]=useState<MapPoint[]>([]);
  const [bbox,setBbox]=useState<string>("");
  const [filter,setFilter]=useState<string>("");
  const busy=useRef(false);

  const load=useCallback(async ()=>{
    if (!bbox || busy.current) return; busy.current=true;
    try{ const data=await fetchMapPoints({bbox, filter: filter || undefined}); setPoints(Array.isArray(data)?data:[]); }
    catch{ /* ignore */ }
    finally{ busy.current=false; }
  },[bbox,filter]);

  useEffect(()=>{ if(bbox) load(); },[bbox,filter,load]);

  return (
    <Box sx={{ position:"relative", height:"calc(100vh - 140px)" }}>
      <MapContainer center={[55.76,37.64]} zoom={6} scrollWheelZoom className="glass">
        <TileLayer attribution="&copy; OSM" url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"/>
        <BboxFetcher onBbox={setBbox}/>
        {points.map(p=>(
          <Marker key={p.id} position={[p.lat,p.lng]} icon={icon}>
            <Popup>
              <b>{p.title}</b><br/>Тип: {p.type}{p.is_highlighted?" ⭐":""}
              {p.photo?.url && <div style={{marginTop:8}}><img src={p.photo.url} style={{maxWidth:180,borderRadius:8}}/></div>}
            </Popup>
          </Marker>
        ))}
      </MapContainer>

      <Box sx={{ position:"absolute", top:12, left:12 }} className="glass">
        <ToggleButtonGroup size="small" exclusive value={filter} onChange={(_,v)=>setFilter(v||"")} sx={{m:1}}>
          <ToggleButton value="">Все</ToggleButton>
          <ToggleButton value="spot">Споты</ToggleButton>
          <ToggleButton value="shop">Магазины</ToggleButton>
          <ToggleButton value="slip">Слипы</ToggleButton>
          <ToggleButton value="camp">Базы</ToggleButton>
        </ToggleButtonGroup>
      </Box>
    </Box>
  );
}
TSX

# 4) Экраны: Лента (реальные уловы), Добавить точку, Добавить улов
cat > src/ui/screens/FeedScreen.tsx <<'TSX'
import { useEffect, useState } from "react";
import { fetchFeedGlobal, CatchItem } from "../data/api";
import { Grid2 as Grid, Stack, Typography, Card, CardContent } from "@mui/material";
import LoadingOverlay from "../components/LoadingOverlay";
import ErrorAlert from "../components/ErrorAlert";

export default function FeedScreen(){
  const [items,setItems]=useState<CatchItem[]>([]);
  const [loading,setLoading]=useState(false);
  const [err,setErr]=useState<string|null>(null);

  useEffect(()=>{ let alive=true; (async ()=>{ setLoading(true);
    try{ const data = await fetchFeedGlobal(); if(alive) setItems(data); }
    catch{ setErr("Не удалось загрузить ленту"); }
    finally{ setLoading(false); }
  })(); return ()=>{ alive=false; }; },[]);

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Лента</Typography>
      {err && <ErrorAlert message={err}/>}
      <Grid container spacing={2}>
        {items.map(it=>(
          <Grid size={{xs:12,md:6}} key={it.id}>
            <Card className="glass"><CardContent>
              <Typography color="white" fontWeight={600}>{it.fish}</Typography>
              <Typography color="#9aa4af">
                {it.weight?`Вес: ${it.weight} кг  `:""}{it.length?`Длина: ${it.length} см`:""} {it.style?` • ${it.style}`:""}
              </Typography>
              {it.photo?.url && <img src={it.photo.url} style={{width:"100%",marginTop:8,borderRadius:12}}/>}
              <Typography color="#9aa4af" variant="caption">{it.created_at && new Date(it.created_at).toLocaleString()}</Typography>
            </CardContent></Card>
          </Grid>
        ))}
      </Grid>
      <LoadingOverlay open={loading}/>
    </Stack>
  );
}
TSX

cat > src/ui/screens/AddPointScreen.tsx <<'TSX'
import { useState } from "react";
import { Box, Button, Card, CardContent, MenuItem, Stack, TextField, Typography, Alert } from "@mui/material";
import { createPoint, uploadImage } from "../data/api";

export default function AddPointScreen(){
  const [form,setForm]=useState({ title:"", type:"spot", lat:"", lng:"" });
  const [photo,setPhoto]=useState<File|null>(null);
  const [status,setStatus]=useState<"idle"|"ok"|"err">("idle");
  const [err,setErr]=useState<string|null>(null);

  const submit=async ()=>{
    try{
      setErr(null); setStatus("idle");
      let photo_id:number|undefined;
      if (photo){ const m = await uploadImage(photo); photo_id = m.id; }
      const payload = { ...form, lat:parseFloat(form.lat), lng:parseFloat(form.lng), photo_id };
      await createPoint(payload as any);
      setStatus("ok"); setForm({ title:"", type:"spot", lat:"", lng:"" }); setPhoto(null);
    }catch(e:any){ setErr("Не удалось добавить точку"); setStatus("err"); }
  };

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Добавить точку</Typography>
      {status==="ok" && <Alert severity="success">Сохранено</Alert>}
      {status==="err" && <Alert severity="error">{err}</Alert>}
      <Card className="glass"><CardContent>
        <Stack spacing={2}>
          <TextField label="Название" value={form.title} onChange={e=>setForm({...form,title:e.target.value})}/>
          <TextField select label="Тип" value={form.type} onChange={e=>setForm({...form,type:e.target.value})}>
            {["spot","shop","slip","camp","catch"].map(t=><MenuItem key={t} value={t}>{t}</MenuItem>)}
          </TextField>
          <Box sx={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:2}}>
            <TextField label="Широта" value={form.lat} onChange={e=>setForm({...form,lat:e.target.value})}/>
            <TextField label="Долгота" value={form.lng} onChange={e=>setForm({...form,lng:e.target.value})}/>
          </Box>
          <Button variant="outlined" component="label">
            Фото
            <input type="file" hidden accept="image/*" onChange={e=>setPhoto(e.target.files?.[0]||null)}/>
          </Button>
          <Button variant="contained" onClick={submit}>Сохранить</Button>
        </Stack>
      </CardContent></Card>
    </Stack>
  );
}
TSX

cat > src/ui/screens/AddCatchScreen.tsx <<'TSX'
import { useState } from "react";
import { Button, Card, CardContent, Grid2 as Grid, MenuItem, Stack, TextField, Typography, Alert } from "@mui/material";
import { createCatch, uploadImage } from "../data/api";

export default function AddCatchScreen(){
  const [form,setForm]=useState({ lat:"", lng:"", fish:"", weight:"", length:"", style:"shore" });
  const [photo,setPhoto]=useState<File|null>(null);
  const [status,setStatus]=useState<"idle"|"ok"|"err">("idle");
  const [err,setErr]=useState<string|null>(null);

  const submit=async ()=>{
    try{
      setErr(null); setStatus("idle");
      let photo_id:number|undefined;
      if (photo){ const m=await uploadImage(photo); photo_id=m.id; }
      const payload = {
        lat:parseFloat(form.lat), lng:parseFloat(form.lng),
        fish:form.fish, weight: form.weight?parseFloat(form.weight):undefined,
        length: form.length?parseFloat(form.length):undefined,
        style: form.style, privacy:'all', photo_id
      };
      await createCatch(payload as any);
      setStatus("ok");
      setForm({ lat:"", lng:"", fish:"", weight:"", length:"", style:"shore" }); setPhoto(null);
    }catch{ setErr("Не удалось добавить улов"); setStatus("err"); }
  };

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Добавить улов</Typography>
      {status==="ok" && <Alert severity="success">Сохранено</Alert>}
      {status==="err" && <Alert severity="error">{err}</Alert>}
      <Card className="glass"><CardContent>
        <Grid container spacing={2}>
          <Grid size={{xs:12,md:6}}>
            <TextField fullWidth label="Широта" value={form.lat} onChange={e=>setForm({...form,lat:e.target.value})}/>
          </Grid>
          <Grid size={{xs:12,md:6}}>
            <TextField fullWidth label="Долгота" value={form.lng} onChange={e=>setForm({...form,lng:e.target.value})}/>
          </Grid>
          <Grid size={{xs:12,md:6}}>
            <TextField fullWidth label="Рыба" value={form.fish} onChange={e=>setForm({...form,fish:e.target.value})}/>
          </Grid>
          <Grid size={{xs:6,md:3}}>
            <TextField fullWidth label="Вес, кг" value={form.weight} onChange={e=>setForm({...form,weight:e.target.value})}/>
          </Grid>
          <Grid size={{xs:6,md:3}}>
            <TextField fullWidth label="Длина, см" value={form.length} onChange={e=>setForm({...form,length:e.target.value})}/>
          </Grid>
          <Grid size={12}>
            <TextField select label="Способ" value={form.style} onChange={e=>setForm({...form,style:e.target.value})}>
              {["shore","boat","ice"].map(s=><MenuItem key={s} value={s}>{s}</MenuItem>)}
            </TextField>
          </Grid>
          <Grid size={12}>
            <Button variant="outlined" component="label">
              Фото
              <input type="file" hidden accept="image/*" onChange={e=>setPhoto(e.target.files?.[0]||null)}/>
            </Button>
          </Grid>
          <Grid size={12}>
            <Button variant="contained" onClick={submit}>Сохранить</Button>
          </Grid>
        </Grid>
      </CardContent></Card>
    </Stack>
  );
}
TSX

# 5) App с маршрутами и «полосой загрузки» на переходах
cat > src/ui/App.tsx <<'TSX'
import { Container, CssBaseline, ThemeProvider, createTheme, LinearProgress, Box } from "@mui/material";
import { Routes, Route, NavLink, useLocation } from "react-router-dom";
import { Suspense, useEffect, useState } from "react";
import MapView from "./components/MapView";
import FeedScreen from "./screens/FeedScreen";
import AddPointScreen from "./screens/AddPointScreen";
import AddCatchScreen from "./screens/AddCatchScreen";

const theme = createTheme({
  palette:{ mode:"dark", primary:{ main:"#57B0E6" }, secondary:{ main:"#1DE9B6" } },
  shape:{ borderRadius:16 }
});

function TopBar(){
  const linkSx = { color:"#fff", textDecoration:"none", marginRight:16 };
  return (
    <div style={{position:"sticky",top:0,zIndex:10,padding:"12px 16px"}} className="glass">
      <NavLink to="/map" style={linkSx as any}>Карта</NavLink>
      <NavLink to="/feed" style={linkSx as any}>Лента</NavLink>
      <NavLink to="/add/point" style={linkSx as any}>+ Точка</NavLink>
      <NavLink to="/add/catch" style={linkSx as any}>+ Улов</NavLink>
    </div>
  );
}

function GlobalLoader(){
  const loc=useLocation(); const [loading,setLoading]=useState(true);
  useEffect(()=>{ setLoading(true); const t=setTimeout(()=>setLoading(false),250); return ()=>clearTimeout(t); },[loc.pathname]);
  return loading ? <LinearProgress/> : null;
}

export default function App(){
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline/>
      <TopBar/>
      <GlobalLoader/>
      <Container sx={{ py:2, pb:12 }}>
        <Suspense fallback={<Box sx={{my:2}}><LinearProgress/></Box>}>
          <Routes>
            <Route path="/" element={<MapView/>}/>
            <Route path="/map" element={<MapView/>}/>
            <Route path="/feed" element={<FeedScreen/>}/>
            <Route path="/add/point" element={<AddPointScreen/>}/>
            <Route path="/add/catch" element={<AddCatchScreen/>}/>
          </Routes>
        </Suspense>
      </Container>
    </ThemeProvider>
  );
}
TSX

echo "==> Frontend S1 готов. Если нужно, установи зависимости: leaflet, @types/leaflet, @mui/material"
bash frontend_sprint1.sh