#!/usr/bin/env bash
set -euo pipefail

FRONT_DIR="frontend"
echo "=> Applying FishTrackPro Front Pack to: $FRONT_DIR"

[ -d "$FRONT_DIR" ] || { echo "Folder '$FRONT_DIR' not found"; exit 1; }

cd "$FRONT_DIR"

# -------- package.json (React 18 + MUI + Leaflet + Router) --------
cat > package.json <<'JSON'
{
  "name": "fishtrackpro-frontend",
  "private": true,
  "version": "0.7.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 5174",
    "lint": "eslint ."
  },
  "dependencies": {
    "@emotion/react": "^11.13.3",
    "@emotion/styled": "^11.13.0",
    "@mui/icons-material": "^6.1.7",
    "@mui/material": "^6.1.7",
    "axios": "^1.7.9",
    "leaflet": "^1.9.4",
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "react-hook-form": "^7.53.0",
    "react-leaflet": "^4.2.1",
    "react-router-dom": "^6.26.2",
    "yup": "^1.4.0",
    "@hookform/resolvers": "^3.9.0"
  },
  "devDependencies": {
    "@types/leaflet": "^1.9.12",
    "@types/node": "^20.14.15",
    "@types/react": "^18.3.11",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.3",
    "eslint": "^9.9.0",
    "eslint-plugin-react": "^7.35.0",
    "typescript": "^5.5.4",
    "vite": "^5.4.3"
  }
}
JSON

# -------- tsconfig.json --------
cat > tsconfig.json <<'JSON'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "jsx": "react-jsx",
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "strict": true,
    "esModuleInterop": true,
    "types": ["vite/client", "leaflet"]
  },
  "include": ["src"]
}
JSON

# -------- vite.config.ts --------
mkdir -p src
cat > vite.config.ts <<'TS'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: { port: 5173, host: true },
  preview: { port: 5174, host: true }
});
TS

# -------- src/index.css --------
mkdir -p src/ui src/ui/components src/ui/screens src/ui/data
cat > src/index.css <<'CSS'
:root { --bg: #0f1216; --glass: rgba(255,255,255,.08); }
* { box-sizing: border-box; }
html, body, #root { height: 100%; }
body { margin: 0; font-family: Inter, system-ui, Arial, sans-serif; background: var(--bg); }
.glass {
  background: var(--glass);
  backdrop-filter: blur(12px) saturate(1.2);
  border: 1px solid rgba(255,255,255,.08);
  border-radius: 16px;
}
.leaflet-container { width: 100%; height: 100%; border-radius: 16px; }
CSS

# -------- src/main.tsx --------
cat > src/main.tsx <<'TSX'
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./ui/App";
import "./index.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>
);
TSX

# -------- index.html --------
cat > index.html <<'HTML'
<!doctype html>
<html lang="ru">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>FishTrackPro</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
      integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin=""/>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
HTML

# -------- src/ui/config/ui.ts --------
mkdir -p src/ui/config
cat > src/ui/config/ui.ts <<'TS'
export type UIConfig = {
  logo: string;
  backgroundPattern: string;
  brand: { primary: string; secondary: string };
  glass: { opacity: number; intensity: number };
};

export const uiConfig: UIConfig = {
  logo: "/logo.svg",
  backgroundPattern: "/bg.svg",
  brand: { primary: "#57B0E6", secondary: "#1DE9B6" },
  glass: { opacity: 0.08, intensity: 12 }
};
TS

# -------- src/ui/data/api.ts --------
cat > src/ui/data/api.ts <<'TS'
import axios from "axios";

const API_BASE = import.meta.env.VITE_API_BASE || "/api";
export const api = axios.create({
  baseURL: `${API_BASE}/v1`,
  timeout: 10000
});

// Типы
export type CatchItem = {
  id: number; lat: number; lng: number;
  fish: string; weight?: number; length?: number;
  photo?: string; user?: { id: number; name: string };
  created_at?: string;
};

export type MapPoint = {
  id: number; lat: number; lng: number;
  title: string; type: "shop" | "slip" | "camp" | "catch" | "spot";
  is_highlighted?: boolean;
};

// API helpers
export async function fetchFeed(tab: "global" | "local" | "follow", coords?: {lat:number; lng:number}) {
  const url = tab === "global" ? "/feed/global" : tab === "follow" ? "/feed/follow" : "/feed/local";
  const params = tab === "local" ? coords : undefined;
  const { data } = await api.get(url, { params });
  return data.items ?? data;
}

export async function fetchMapPoints(params: { bbox?: string; filter?: string }) {
  const { data } = await api.get("/map/points", { params });
  return data.items ?? data;
}

export async function createCatch(payload: any) {
  const { data } = await api.post("/catches", payload);
  return data;
}

export async function createEvent(payload: any) {
  const { data } = await api.post("/events", payload);
  return data;
}

export async function createPoint(payload: any) {
  const { data } = await api.post("/map/points", payload);
  return data;
}

export async function health() {
  return api.get("/health").then(r => r.data);
}
TS

# -------- src/ui/components/BottomNav.tsx --------
cat > src/ui/components/BottomNav.tsx <<'TSX'
import { BottomNavigation, BottomNavigationAction, Paper } from "@mui/material";
import MapIcon from "@mui/icons-material/Map";
import DynamicFeedIcon from "@mui/icons-material/DynamicFeed";
import AddLocationAltIcon from "@mui/icons-material/AddLocationAlt";
import EventIcon from "@mui/icons-material/Event";
import AddCircleIcon from "@mui/icons-material/AddCircle";
import { useLocation, useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";

export default function BottomNav() {
  const nav = useNavigate();
  const loc = useLocation();
  const [value, setValue] = useState(0);

  useEffect(() => {
    if (loc.pathname.startsWith("/map")) setValue(0);
    else if (loc.pathname.startsWith("/feed")) setValue(1);
    else if (loc.pathname.startsWith("/add/point")) setValue(2);
    else if (loc.pathname.startsWith("/events")) setValue(3);
    else setValue(-1);
  }, [loc.pathname]);

  return (
    <Paper sx={{ position: "fixed", bottom: 12, left: 12, right: 12, borderRadius: 4 }} elevation={6} className="glass">
      <BottomNavigation
        value={value}
        onChange={(_, v) => setValue(v)}
        showLabels
      >
        <BottomNavigationAction label="Карта" icon={<MapIcon />} onClick={() => nav("/map")} />
        <BottomNavigationAction label="Лента" icon={<DynamicFeedIcon />} onClick={() => nav("/feed")} />
        <BottomNavigationAction label="Точка" icon={<AddLocationAltIcon />} onClick={() => nav("/add/point")} />
        <BottomNavigationAction label="События" icon={<EventIcon />} onClick={() => nav("/events")} />
        <BottomNavigationAction label="Улов" icon={<AddCircleIcon />} onClick={() => nav("/add/catch")} />
      </BottomNavigation>
    </Paper>
  );
}
TSX

# -------- src/ui/components/MapView.tsx (Leaflet + демо-точки) --------
cat > src/ui/components/MapView.tsx <<'TSX'
import { useEffect, useMemo, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { fetchMapPoints, MapPoint } from "../data/api";

const icon = L.icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41]
});

const DEMO: MapPoint[] = [
  { id: 1, lat: 55.751244, lng: 37.618423, title: "Спот: Москва-река", type: "spot", is_highlighted: true },
  { id: 2, lat: 59.93863, lng: 30.31413, title: "Магазин снастей", type: "shop" },
  { id: 3, lat: 60.003, lng: 30.2, title: "Слип", type: "slip" }
];

export default function MapView() {
  const [points, setPoints] = useState<MapPoint[]>(DEMO);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;
    fetchMapPoints({})
      .then((items) => { if (mounted && Array.isArray(items) && items.length) setPoints(items); })
      .catch(() => { /* оставляем DEMO */ })
    return () => { mounted = false; }
  }, []);

  const center = useMemo(() => [55.76, 37.64] as [number, number], []);
  return (
    <div style={{ height: "calc(100vh - 140px)" }}>
      <MapContainer center={center} zoom={6} scrollWheelZoom className="glass">
        <TileLayer
          attribution='&copy; <a href="https://osm.org">OSM</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {points.map(p => (
          <Marker key={p.id} position={[p.lat, p.lng]} icon={icon}>
            <Popup>
              <b>{p.title}</b><br/>
              Тип: {p.type}{p.is_highlighted ? " ⭐" : ""}
            </Popup>
          </Marker>
        ))}
      </MapContainer>
      {error && <div style={{color:'salmon', marginTop:8}}>Ошибка карты: {error}</div>}
    </div>
  );
}
TSX

# -------- src/ui/screens/FeedScreen.tsx --------
cat > src/ui/screens/FeedScreen.tsx <<'TSX'
import { useEffect, useState } from "react";
import { fetchFeed, CatchItem } from "../data/api";
import { Box, Chip, Grid2 as Grid, Stack, Typography, Card, CardContent, Avatar } from "@mui/material";

type Tab = "global" | "local" | "follow";

export default function FeedScreen() {
  const [tab, setTab] = useState<Tab>("global");
  const [items, setItems] = useState<CatchItem[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    setLoading(true);
    const coords = tab === "local" ? { lat: 55.76, lng: 37.64 } : undefined;
    fetchFeed(tab, coords).then(setItems).catch(() => {
      // DEMO
      setItems([
        { id: 101, lat: 55.7, lng: 37.6, fish: "Щука", weight: 3.2, user: { id: 1, name: "Demo" }, photo: "", created_at: new Date().toISOString() },
        { id: 102, lat: 59.9, lng: 30.3, fish: "Окунь", weight: 0.7, user: { id: 2, name: "Test" } }
      ]);
    }).finally(() => setLoading(false));
  }, [tab]);

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Лента</Typography>
      <Stack direction="row" spacing={1}>
        <Chip label="Global" color={tab==="global"?"primary":"default"} onClick={()=>setTab("global")} />
        <Chip label="Local"  color={tab==="local" ?"primary":"default"} onClick={()=>setTab("local")} />
        <Chip label="Follow" color={tab==="follow"?"primary":"default"} onClick={()=>setTab("follow")} />
      </Stack>

      <Grid container spacing={2}>
        {items.map((it) => (
          <Grid size={{ xs: 12, md: 6 }} key={it.id}>
            <Card className="glass">
              <CardContent>
                <Stack direction="row" spacing={2} alignItems="center">
                  <Avatar>{(it.user?.name ?? "U").slice(0,1)}</Avatar>
                  <Stack>
                    <Typography color="white">{it.user?.name ?? "Аноним"}</Typography>
                    <Typography variant="body2" color="#9aa4af">{new Date(it.created_at ?? Date.now()).toLocaleString()}</Typography>
                  </Stack>
                </Stack>
                <Typography mt={2} color="white">
                  Улов: {it.fish} {it.weight ? `• ${it.weight} кг` : ""} {it.length ? `• ${it.length} см` : ""}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {loading && <Typography color="#9aa4af">Загрузка…</Typography>}
    </Stack>
  );
}
TSX

# -------- src/ui/screens/AddCatchScreen.tsx --------
cat > src/ui/screens/AddCatchScreen.tsx <<'TSX'
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { Button, Grid2 as Grid, MenuItem, Stack, TextField, Typography } from "@mui/material";
import { createCatch } from "../data/api";
import { useState } from "react";

const schema = z.object({
  lat: z.coerce.number(),
  lng: z.coerce.number(),
  fish: z.string().min(2),
  weight: z.coerce.number().optional(),
  length: z.coerce.number().optional(),
  style: z.enum(["shore","boat","ice"]).default("shore"),
  privacy: z.enum(["all","friends","groups","none"]).default("all")
});
type Form = z.infer<typeof schema>;

export default function AddCatchScreen() {
  const [ok, setOk] = useState<string | null>(null);
  const { register, handleSubmit, formState:{errors}, reset } = useForm<Form>({
    resolver: zodResolver(schema),
    defaultValues: { lat:55.76, lng:37.64, style:"shore", privacy:"all" }
  });

  const onSubmit = async (values: Form) => {
    setOk(null);
    try {
      await createCatch(values);
      setOk("Сохранено!");
      reset();
    } catch {
      setOk("DEMO: локально сохранено (без API).");
    }
  };

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Добавить улов</Typography>
      <form onSubmit={handleSubmit(onSubmit)}>
        <Grid container spacing={2}>
          <Grid size={6}><TextField label="Широта" fullWidth {...register("lat")} error={!!errors.lat} /></Grid>
          <Grid size={6}><TextField label="Долгота" fullWidth {...register("lng")} error={!!errors.lng} /></Grid>
          <Grid size={12}><TextField label="Вид рыбы" fullWidth {...register("fish")} error={!!errors.fish} /></Grid>
          <Grid size={6}><TextField label="Вес (кг)" fullWidth type="number" {...register("weight")} /></Grid>
          <Grid size={6}><TextField label="Длина (см)" fullWidth type="number" {...register("length")} /></Grid>
          <Grid size={6}>
            <TextField select label="Вид ловли" fullWidth defaultValue="shore" {...register("style")}>
              <MenuItem value="shore">Берег</MenuItem>
              <MenuItem value="boat">Лодка</MenuItem>
              <MenuItem value="ice">Лёд</MenuItem>
            </TextField>
          </Grid>
          <Grid size={6}>
            <TextField select label="Приватность" fullWidth defaultValue="all" {...register("privacy")}>
              <MenuItem value="all">Все авторизованные</MenuItem>
              <MenuItem value="friends">Только друзья</MenuItem>
              <MenuItem value="groups">Группы</MenuItem>
              <MenuItem value="none">Никому</MenuItem>
            </TextField>
          </Grid>
          <Grid size={12}><Button variant="contained" type="submit">Сохранить</Button></Grid>
        </Grid>
      </form>
      {ok && <Typography color="#1DE9B6">{ok}</Typography>}
    </Stack>
  );
}
TSX

# -------- src/ui/screens/AddPointScreen.tsx --------
cat > src/ui/screens/AddPointScreen.tsx <<'TSX'
import { Button, Grid2 as Grid, MenuItem, Stack, TextField, Typography } from "@mui/material";
import { useForm } from "react-hook-form";
import { createPoint } from "../data/api";

type Form = { lat:number; lng:number; title:string; type:"shop"|"slip"|"camp"|"spot" };

export default function AddPointScreen() {
  const { register, handleSubmit, reset } = useForm<Form>({ defaultValues:{lat:55.76,lng:37.64,type:"spot"} });

  const onSubmit = async (v:Form) => {
    try { await createPoint(v); alert("Сохранено!"); reset(); }
    catch { alert("DEMO: точка сохранена локально (без API)"); }
  };

  return (
    <Stack spacing={2}>
      <Typography variant="h5" color="white">Добавить точку</Typography>
      <form onSubmit={handleSubmit(onSubmit)}>
        <Grid container spacing={2}>
          <Grid size={6}><TextField label="Широта" fullWidth {...register("lat", { valueAsNumber:true })}/></Grid>
          <Grid size={6}><TextField label="Долгота" fullWidth {...register("lng", { valueAsNumber:true })}/></Grid>
          <Grid size={12}><TextField label="Название" fullWidth {...register("title")} /></Grid>
          <Grid size={12}>
            <TextField select label="Тип" fullWidth defaultValue="spot" {...register("type")}>
              <MenuItem value="spot">Спот</MenuItem>
              <MenuItem value="shop">Магазин</MenuItem>
              <MenuItem value="slip">Слип</MenuItem>
              <MenuItem value="camp">Турбаза</MenuItem>
            </TextField>
          </Grid>
          <Grid size={12}><Button variant="contained" type="submit">Сохранить</Button></Grid>
        </Grid>
      </form>
    </Stack>
  );
}
TSX

# -------- src/ui/screens/EventsScreen.tsx (список + кнопка добавления) --------
cat > src/ui/screens/EventsScreen.tsx <<'TSX'
import { Button, Card, CardContent, Grid2 as Grid, Stack, TextField, Typography } from "@mui/material";
import { useEffect, useState } from "react";
import { createEvent } from "../data/api";

type EventItem = { id:number; title:string; region?:string; starts_at?:string; description?:string };

export default function EventsScreen() {
  const [items, setItems] = useState<EventItem[]>([
    { id:1, title:"Кубок по спиннингу", region:"RU-MOW", starts_at:new Date().toISOString(), description:"Демо событие" }
  ]);

  const [creating, setCreating] = useState(false);
  const [form, setForm] = useState({ title:"", region:"", starts_at:"" });

  const submit = async () => {
    try {
      const res = await createEvent(form);
      setItems([res, ...items]);
      setCreating(false);
    } catch {
      setItems([{ id: items.length+1, ...form }, ...items]);
      setCreating(false);
    }
  };

  return (
    <Stack spacing={2}>
      <Stack direction="row" justifyContent="space-between" alignItems="center">
        <Typography variant="h5" color="white">События</Typography>
        <Button variant="contained" onClick={()=>setCreating(true)}>Добавить</Button>
      </Stack>

      {creating && (
        <Card className="glass">
          <CardContent>
            <Stack spacing={2}>
              <TextField label="Название" value={form.title} onChange={e=>setForm({...form, title:e.target.value})}/>
              <TextField label="Регион" value={form.region} onChange={e=>setForm({...form, region:e.target.value})}/>
              <TextField label="Дата" type="datetime-local" value={form.starts_at} onChange={e=>setForm({...form, starts_at:e.target.value})}/>
              <Button variant="contained" onClick={submit}>Сохранить</Button>
            </Stack>
          </CardContent>
        </Card>
      )}

      <Grid container spacing={2}>
        {items.map(ev => (
          <Grid size={{ xs:12, md:6 }} key={ev.id}>
            <Card className="glass"><CardContent>
              <Typography color="white" fontWeight={600}>{ev.title}</Typography>
              <Typography color="#9aa4af">{ev.region}</Typography>
              <Typography color="#9aa4af">{ev.starts_at && new Date(ev.starts_at).toLocaleString()}</Typography>
              <Typography color="white">{ev.description}</Typography>
            </CardContent></Card>
          </Grid>
        ))}
      </Grid>
    </Stack>
  );
}
TSX

# -------- src/ui/App.tsx (один Router — в main.tsx!) --------
cat > src/ui/App.tsx <<'TSX'
import { Container, CssBaseline, ThemeProvider, createTheme } from "@mui/material";
import { Routes, Route, Link, NavLink } from "react-router-dom";
import MapView from "./components/MapView";
import FeedScreen from "./screens/FeedScreen";
import AddCatchScreen from "./screens/AddCatchScreen";
import AddPointScreen from "./screens/AddPointScreen";
import EventsScreen from "./screens/EventsScreen";
import BottomNav from "./components/BottomNav";

const theme = createTheme({
  palette: { mode: "dark", primary: { main: "#57B0E6" }, secondary: { main: "#1DE9B6" } },
  shape: { borderRadius: 16 }
});

function TopBar() {
  const linkSx = { color: "#fff", textDecoration: "none", marginRight: 16 };
  return (
    <div style={{position:"sticky",top:0,zIndex:10,padding:"12px 16px"}} className="glass">
      <NavLink to="/map" style={linkSx as any}>Карта</NavLink>
      <NavLink to="/feed" style={linkSx as any}>Лента</NavLink>
      <NavLink to="/events" style={linkSx as any}>События</NavLink>
    </div>
  );
}

export default function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <TopBar />
      <Container sx={{ py: 2, pb: 12 }}>
        <Routes>
          <Route path="/" element={<MapView />} />
          <Route path="/map" element={<MapView />} />
          <Route path="/feed" element={<FeedScreen />} />
          <Route path="/events" element={<EventsScreen />} />
          <Route path="/add/catch" element={<AddCatchScreen />} />
          <Route path="/add/point" element={<AddPointScreen />} />
        </Routes>
      </Container>
      <BottomNav />
    </ThemeProvider>
  );
}
TSX

# -------- .env.development.local (пример) --------
cat > .env <<'ENV'
VITE_API_BASE=/api
ENV

echo "=> Installing deps (this may take a while)…"
rm -rf node_modules package-lock.json
npm i

echo "=> Done. Start dev server:"
echo "   npm run dev"
