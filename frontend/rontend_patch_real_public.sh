#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

mkdir -p src/ui/{components,screens,data}
touch src/index.css

# --- API (реальные эндпоинты) ---
cat > src/ui/data/api.ts <<'TS'
import axios from "axios";
const API_BASE = import.meta.env.VITE_API_BASE || "/api";
export const api = axios.create({ baseURL: `${API_BASE}/v1`, timeout: 10000 });

export type MapPoint = { id:number; lat:number; lng:number; title:string; type:string; is_highlighted?:boolean };
export type CatchItem = { id:number; lat:number; lng:number; fish:string; weight?:number; length?:number; created_at?:string };
export type EventItem = { id:number; title:string; region?:string; starts_at?:string; description?:string };
export type Club = { id:number; name:string; description?:string; logo?:string };

export async function health(){ return (await api.get("/health")).data; }

export async function fetchMapPoints(params?:{bbox?:string;filter?:string}){
  const { data } = await api.get("/map/points",{ params }); return data.items ?? data;
}
export async function createPoint(payload:any){ return (await api.post("/map/points", payload)).data; }

export async function fetchFeedGlobal(){ const { data } = await api.get("/feed/global"); return data.items ?? []; }
export async function fetchFeedLocal(lat:number,lng:number){ const { data } = await api.get("/feed/local",{ params:{lat,lng} }); return data.items ?? []; }

export async function createCatch(payload:any){ return (await api.post("/catches", payload)).data; }

export async function fetchEvents(params?:any){ const { data } = await api.get("/events",{ params }); return data.items ?? []; }
export async function createEvent(payload:any){ return (await api.post("/events", payload)).data; }

export async function fetchClubs(){ const { data } = await api.get("/clubs"); return data.items ?? []; }
export async function createClub(payload:Partial<Club>){ return (await api.post("/clubs", payload)).data; }
TS

# --- Виджеты: лоадер + ошибка ---
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

# --- Карта (реальные данные + bbox) ---
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
    if (busy.current) return; busy.current=true;
    try{ const data=await fetchMapPoints({bbox, filter: filter || undefined}); setPoints(Array.isArray(data)?data:[]); }
    catch{ /* тихо */ }
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
            <Popup><b>{p.title}</b><br/>Тип: {p.type}{p.is_highlighted?" ⭐":""}</Popup>
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

# --- Лента (реальные данные из /feed/global и /feed/local) ---
cat > src/ui/screens/FeedScreen.tsx <<'TSX'
import { useEffect, useState } from "react";
import { fetchFeedGlobal, fetchFeedLocal, CatchItem } from "../data/api";
import { Box, Chip, Grid2 as Grid, Stack, Typography, Card, CardContent } from "@mui/material";
import LoadingOverlay from "../components/LoadingOverlay";
import ErrorAlert from "../components/ErrorAlert";

type Tab = "global" | "local";
export default function FeedScreen(){
  const [tab,setTab]=useState<Tab>("global");
  const [items,setItems]=useState<CatchItem[]>([]);
  const [loading,setLoading]=useState(false);
  const [err,setErr]=useState<string|null>(null);

  useEffect(()=>{ let alive=true; (async ()=>{
    setLoading(true); setErr(null);
    try{
      const data = tab==="global" ? await fetchFeedGlobal() : await fetchFeedLocal(55.76,37.64);
      if(alive) setItems(data);
    }catch(e:any){ setErr("Не удалось загрузить ленту"); }
    finally{ setLoading(false); }
  })(); return ()=>{ alive=false; }; },[tab]);

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Лента</Typography>
      <Stack direction="row" spacing={1}>
        <Chip label="Global" color={tab==="global"?"primary":"default"} onClick={()=>setTab("global")} />
        <Chip label="Local"  color={tab==="local" ?"primary":"default"} onClick={()=>setTab("local")} />
      </Stack>
      {err && <ErrorAlert message={err}/>}
      <Grid container spacing={2}>
        {items.map(it=>(
          <Grid size={{xs:12,md:6}} key={it.id}>
            <Card className="glass"><CardContent>
              <Typography color="white" fontWeight={600}>{it.fish}</Typography>
              <Typography color="#9aa4af">{it.weight?`Вес: ${it.weight} кг  `:""}{it.length?`Длина: ${it.length} см`:""}</Typography>
              <Typography color="#9aa4af">{new Date(it.created_at ?? Date.now()).toLocaleString()}</Typography>
            </CardContent></Card>
          </Grid>
        ))}
      </Grid>
      <LoadingOverlay open={loading}/>
    </Stack>
  );
}
TSX

# --- События (реальные /events) ---
cat > src/ui/screens/EventsScreen.tsx <<'TSX'
import { useEffect, useState } from "react";
import { fetchEvents, createEvent, EventItem } from "../data/api";
import { Button, Card, CardContent, Grid2 as Grid, Stack, TextField, Typography } from "@mui/material";
import LoadingOverlay from "../components/LoadingOverlay";
import ErrorAlert from "../components/ErrorAlert";

export default function EventsScreen(){
  const [items,setItems]=useState<EventItem[]>([]);
  const [loading,setLoading]=useState(false);
  const [err,setErr]=useState<string|null>(null);
  const [creating,setCreating]=useState(false);
  const [form,setForm]=useState({ title:"", region:"", starts_at:"" });

  const load=async ()=>{ setLoading(true); setErr(null);
    try{ setItems(await fetchEvents()); } catch{ setErr("Не удалось загрузить события"); }
    finally{ setLoading(false); } };

  useEffect(()=>{ load(); },[]);

  const submit=async ()=>{ try{ await createEvent(form as any); setCreating(false); setForm({title:"",region:"",starts_at:""}); load(); }catch{ setErr("Не удалось создать событие"); } };

  return (
    <Stack spacing={2}>
      <Stack direction="row" justifyContent="space-between" alignItems="center">
        <Typography variant="h5" color="white">События</Typography>
        <Button variant="contained" onClick={()=>setCreating(true)}>Добавить</Button>
      </Stack>
      {err && <ErrorAlert message={err}/>}
      {creating && (
        <Card className="glass"><CardContent>
          <Stack spacing={2}>
            <TextField label="Название" value={form.title} onChange={e=>setForm({...form,title:e.target.value})}/>
            <TextField label="Регион" value={form.region} onChange={e=>setForm({...form,region:e.target.value})}/>
            <TextField label="Дата" type="datetime-local" value={form.starts_at} onChange={e=>setForm({...form,starts_at:e.target.value})}/>
            <Button variant="contained" onClick={submit}>Сохранить</Button>
          </Stack>
        </CardContent></Card>
      )}
      <Grid container spacing={2}>
        {items.map(ev=>(
          <Grid size={{xs:12,md:6}} key={ev.id}>
            <Card className="glass"><CardContent>
              <Typography color="white" fontWeight={600}>{ev.title}</Typography>
              <Typography color="#9aa4af">{ev.region}</Typography>
              <Typography color="#9aa4af">{ev.starts_at && new Date(ev.starts_at).toLocaleString()}</Typography>
              <Typography color="white">{ev.description}</Typography>
            </CardContent></Card>
          </Grid>
        ))}
      </Grid>
      <LoadingOverlay open={loading}/>
    </Stack>
  );
}
TSX

# --- Клубы (реальные /clubs) ---
cat > src/ui/screens/ClubsScreen.tsx <<'TSX'
import { useEffect, useState } from "react";
import { fetchClubs, createClub, Club } from "../data/api";
import { Button, Card, CardContent, Grid2 as Grid, Stack, TextField, Typography } from "@mui/material";
import LoadingOverlay from "../components/LoadingOverlay";
import ErrorAlert from "../components/ErrorAlert";

export default function ClubsScreen(){
  const [items,setItems]=useState<Club[]>([]);
  const [loading,setLoading]=useState(false);
  const [err,setErr]=useState<string|null>(null);
  const [creating,setCreating]=useState(false);
  const [form,setForm]=useState<Partial<Club>>({ name:"", description:"" });

  const load=async ()=>{ setLoading(true); setErr(null); try{ setItems(await fetchClubs()); }catch{ setErr("Не удалось загрузить клубы"); } finally{ setLoading(false); } };
  useEffect(()=>{ load(); },[]);

  const submit=async ()=>{ try{ await createClub(form); setCreating(false); setForm({ name:"", description:"" }); load(); }catch{ setErr("Не удалось создать клуб"); } };

  return (
    <Stack spacing={2}>
      <Stack direction="row" justifyContent="space-between" alignItems="center">
        <Typography variant="h5" color="white">Клубы</Typography>
        <Button variant="contained" onClick={()=>setCreating(true)}>Создать</Button>
      </Stack>
      {err && <ErrorAlert message={err}/>}
      {creating && (
        <Card className="glass"><CardContent>
          <Stack spacing={2}>
            <TextField label="Название" value={form.name||""} onChange={e=>setForm({...form,name:e.target.value})}/>
            <TextField label="Описание" value={form.description||""} onChange={e=>setForm({...form,description:e.target.value})}/>
            <Button variant="contained" onClick={submit}>Сохранить</Button>
          </Stack>
        </CardContent></Card>
      )}
      <Grid container spacing={2}>
        {items.map(c=>(
          <Grid size={{xs:12,md:6}} key={c.id}>
            <Card className="glass"><CardContent>
              <Typography color="white" fontWeight={600}>{c.name}</Typography>
              <Typography color="#9aa4af">{c.description}</Typography>
            </CardContent></Card>
          </Grid>
        ))}
      </Grid>
      <LoadingOverlay open={loading}/>
    </Stack>
  );
}
TSX

# --- Низ навигации и App с «заставкой» ---
cat > src/ui/components/BottomNav.tsx <<'TSX'
import { BottomNavigation, BottomNavigationAction, Paper } from "@mui/material";
import MapIcon from "@mui/icons-material/Map";
import DynamicFeedIcon from "@mui/icons-material/DynamicFeed";
import EventIcon from "@mui/icons-material/Event";
import GroupsIcon from "@mui/icons-material/Groups";
import { useLocation, useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";

export default function BottomNav(){
  const nav=useNavigate(); const loc=useLocation(); const [value,setValue]=useState(0);
  useEffect(()=>{ if(loc.pathname.startsWith("/map")) setValue(0);
    else if(loc.pathname.startsWith("/feed")) setValue(1);
    else if(loc.pathname.startsWith("/events")) setValue(2);
    else if(loc.pathname.startsWith("/clubs")) setValue(3);
    else setValue(-1); },[loc.pathname]);
  return (
    <Paper sx={{position:"fixed",bottom:12,left:12,right:12,borderRadius:4}} elevation={6} className="glass">
      <BottomNavigation value={value} onChange={(_,v)=>setValue(v)} showLabels>
        <BottomNavigationAction label="Карта" icon={<MapIcon/>} onClick={()=>nav("/map")}/>
        <BottomNavigationAction label="Лента" icon={<DynamicFeedIcon/>} onClick={()=>nav("/feed")}/>
        <BottomNavigationAction label="События" icon={<EventIcon/>} onClick={()=>nav("/events")}/>
        <BottomNavigationAction label="Клубы" icon={<GroupsIcon/>} onClick={()=>nav("/clubs")}/>
      </BottomNavigation>
    </Paper>
  );
}
TSX

cat > src/ui/App.tsx <<'TSX'
import { Container, CssBaseline, ThemeProvider, createTheme, LinearProgress, Box } from "@mui/material";
import { Routes, Route, NavLink, useLocation } from "react-router-dom";
import { Suspense, useEffect, useState } from "react";
import MapView from "./components/MapView";
import FeedScreen from "./screens/FeedScreen";
import EventsScreen from "./screens/EventsScreen";
import ClubsScreen from "./screens/ClubsScreen";
import BottomNav from "./components/BottomNav";

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
      <NavLink to="/events" style={linkSx as any}>События</NavLink>
      <NavLink to="/clubs" style={linkSx as any}>Клубы</NavLink>
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
            <Route path="/events" element={<EventsScreen/>}/>
            <Route path="/clubs" element={<ClubsScreen/>}/>
          </Routes>
        </Suspense>
      </Container>
      <BottomNav/>
    </ThemeProvider>
  );
}
TSX

echo "==> Frontend real public patch applied."
