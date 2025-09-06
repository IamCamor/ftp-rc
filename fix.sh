#!/usr/bin/env bash
set -euo pipefail

# ====== ПАРАМЕТРЫ (подкорректируй при необходимости) ======
FRONTEND_DIR="frontend"
BACKEND_DIR="backend"
API_BASE="https://api.fishtrackpro.ru/api/v1"
PUBLIC_SITE="https://www.fishtrackpro.ru"
TILES_URL="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"

# ====== ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ЗАПИСИ ФАЙЛОВ ======
write_file() {
  local path="$1"; shift
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<'EOF'
'"$@"'
EOF
}

echo "→ Проверяю папки..."
[ -d "$FRONTEND_DIR" ] || { echo "❌ Нет папки $FRONTEND_DIR"; exit 1; }
[ -d "$BACKEND_DIR" ] || { echo "❌ Нет папки $BACKEND_DIR"; exit 1; }

# ====== FRONTEND: index.html (Material Symbols правильный selector) ======
INDEX_HTML="${FRONTEND_DIR}/index.html"
if [ -f "$INDEX_HTML" ]; then
  echo "→ Патчу index.html (Material Symbols, meta, OSM)"
  # Добавляем линк на Material Symbols Rounded с правильной осью:
  # family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,400,0,0
  tmp="${INDEX_HTML}.tmp"
  awk '
    BEGIN{added=0}
    /<\/head>/ && !added {
      print "  <link rel=\"preconnect\" href=\"https://fonts.googleapis.com\">"
      print "  <link rel=\"preconnect\" href=\"https://fonts.gstatic.com\" crossorigin>"
      print "  <link href=\"https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,400,0,0\" rel=\"stylesheet\">"
      print "  <style>.material-symbols-rounded{font-variation-settings:\x27FILL\x27 0, \x27wght\x27 400, \x27GRAD\x27 0, \x27opsz\x27 24; vertical-align: -6px;}</style>"
      added=1
    }
    {print}
  ' "$INDEX_HTML" > "$tmp" && mv "$tmp" "$INDEX_HTML"
else
  echo "⚠️ ${INDEX_HTML} не найден — пропускаю."
fi

# ====== FRONTEND: styles/app.css с glassmorphism ======
write_file "${FRONTEND_DIR}/src/styles/app.css" '
:root{
  --header-h:56px; --bottom-h:64px; --blur:12px;
  --glass: rgba(255,255,255,0.08);
  --glass-border: rgba(255,255,255,0.25);
}
html,body,#root{height:100%;margin:0;background:#0b0e14;color:#e6e6e6;font-family:Inter, system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;}
.app-shell{display:grid;grid-template-rows:var(--header-h) 1fr var(--bottom-h);height:100%;}
.header,.bottom{
  backdrop-filter: blur(var(--blur));
  -webkit-backdrop-filter: blur(var(--blur));
  background: linear-gradient(180deg, rgba(255,255,255,0.10), rgba(255,255,255,0.04));
  border-bottom:1px solid var(--glass-border);
}
.bottom{border-top:1px solid var(--glass-border); border-bottom:none;}
.header-inner, .bottom-inner{max-width:1200px;margin:0 auto;display:flex;align-items:center;gap:12px;height:100%;padding:0 12px;}
.icon{font-family:"Material Symbols Rounded";font-weight:normal;font-style:normal;display:inline-block;line-height:1;font-size:24px}
.glass-card{
  background: var(--glass); border:1px solid var(--glass-border);
  border-radius:16px; backdrop-filter: blur(var(--blur)); -webkit-backdrop-filter: blur(var(--blur));
}
.map-wrap{position:relative;height:100%;width:100%;}
.map-overlay{position:absolute;top:12px;left:12px;right:12px;display:flex;gap:12px;z-index:1000}
.map-fab{
  position:absolute;right:12px;bottom:12px;z-index:1000;
  width:56px;height:56px;border-radius:50%;display:flex;align-items:center;justify-content:center;
  background: #2b6cb0; color:#fff; border:none; cursor:pointer; box-shadow:0 10px 30px rgba(0,0,0,.3);
}
.leaflet-container{height:100%;width:100%;border-radius:12px;overflow:hidden}
a{color:inherit;text-decoration:none}
button{cursor:pointer}
input,select,textarea{
  background: rgba(255,255,255,0.06); border:1px solid var(--glass-border); color:#e6e6e6;
  border-radius:12px; padding:10px 12px; width:100%;
}
form .row{display:grid;grid-template-columns:1fr 1fr;gap:12px}
form .row > * {width:100%}
.card{padding:12px}
.badge{padding:4px 8px;border-radius:999px;background:rgba(255,255,255,0.1);font-size:12px}
.toolbar{display:flex;gap:8px;align-items:center}
'

# ====== FRONTEND: config.ts ======
write_file "${FRONTEND_DIR}/src/config.ts" "
export const API_BASE = '${API_BASE}';
export const PUBLIC_SITE = '${PUBLIC_SITE}';
export const TILES_URL = '${TILES_URL}';

export const ICONS = {
  header: { weather: 'device_thermostat', bell: 'notifications', add: 'add_circle', profile: 'account_circle' },
  bottom: { feed: 'home', map: 'map', addCatch: 'add_photo_alternate', addPlace: 'add_location', alerts: 'notifications', profile: 'person' },
  actions: { like: 'favorite', comment: 'mode_comment', share: 'share', open: 'open_in_new', weatherSave: 'cloud_download' },
};

export const UI_DIMENSIONS = { header: 56, bottomNav: 64 };

export const DEFAULT_IMAGES = {
  logo: '/assets/logo.svg',
  avatar: '/assets/default-avatar.png',
  backgroundPattern: '/assets/pattern.png',
};
"

# ====== FRONTEND: types.ts ======
write_file "${FRONTEND_DIR}/src/types.ts" '
export type LatLng = { lat:number; lng:number };

export type Point = {
  id:number; type:"spot"|"service"|"warning"|"place";
  title:string; lat:number; lng:number; photos?:string[]; catches_count?:number;
};

export type FeedItem = {
  id:number; user_id:number; user_name:string; user_avatar:string;
  lat:number; lng:number; species?:string; length?:number; weight?:number;
  method?:string; bait?:string; gear?:string; caption?:string;
  media_url?:string; created_at:string; likes_count:number; comments_count:number; liked_by_me:number;
};

export type Profile = {
  id:number; name:string; avatar?:string; points:number; rating?:number; bio?:string;
};

export type WeatherFav = { id:string; name:string; lat:number; lng:number };
export type Notification = { id:number; title:string; body:string; created_at:string; read?:boolean };
export type Banner = { id:number; image:string; url:string; position:"feed_top"|"feed_inline"|"map_top"|"profile_top" };
'

# ====== FRONTEND: api.ts ======
write_file "${FRONTEND_DIR}/src/api.ts" '
import { API_BASE } from "./config";
import type { Point, FeedItem, Profile, WeatherFav, Notification, Banner } from "./types";

const j = async (res: Response) => {
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json();
};

// базовая обёртка
const req = async (path:string, init?:RequestInit) => {
  const res = await fetch(`${API_BASE}${path}`, {
    credentials: "include",
    headers: { "Content-Type": "application/json" },
    ...init,
  });
  return j(res);
};

// === Карта / точки ===
export const getPoints = (params: {limit?:number; bbox?:string; filter?:string} = {}) => {
  const q = new URLSearchParams();
  if (params.limit) q.set("limit", String(params.limit));
  if (params.bbox) q.set("bbox", params.bbox);
  if (params.filter) q.set("filter", params.filter);
  return req(`/map/points?${q.toString()}`);
};
export const addPoint = (payload: any) => req("/points", { method:"POST", body: JSON.stringify(payload) });
export const getPlaceById = (id:number) => req(`/map/points/${id}`);

// === Лента ===
export const getFeed = (limit=10, offset=0): Promise<FeedItem[]> => req(`/feed?limit=${limit}&offset=${offset}`);
export const getCatchById = (id:number) => req(`/catch/${id}`);
export const addCatch = (payload:any) => req(`/catches`, { method:"POST", body: JSON.stringify(payload) });
export const addComment = (catchId:number, payload:{text:string}) => req(`/catch/${catchId}/comments`, { method:"POST", body: JSON.stringify(payload) });
export const toggleLike = (catchId:number) => req(`/catch/${catchId}/like`, { method:"POST" });

// === Погода ===
export const getWeather = (lat:number,lng:number, dt?:number) => {
  const q = new URLSearchParams({ lat:String(lat), lng:String(lng) });
  if (dt) q.set("dt", String(dt));
  return req(`/weather?${q.toString()}`);
};
export const getWeatherFavs = (): WeatherFav[] => {
  const raw = localStorage.getItem("weather_favs") || "[]";
  try { return JSON.parse(raw) } catch { return [] }
};
export const saveWeatherFav = (fav: WeatherFav) => {
  const list = getWeatherFavs();
  const i = list.findIndex(x => x.id === fav.id);
  if (i>=0) list[i] = fav; else list.push(fav);
  localStorage.setItem("weather_favs", JSON.stringify(list));
  return list;
};

// === Авторизация / Профиль ===
export const login = (email:string, password:string) => req("/auth/login", { method:"POST", body: JSON.stringify({email,password}) });
export const logout = () => req("/auth/logout", { method:"POST" });
export const me = (): Promise<Profile> => req("/auth/me");
export const updateProfile = (payload:any) => req("/profile/update", { method:"POST", body: JSON.stringify(payload) });

// === Рейтинги / Баллы / Баннеры ===
export const getRatings = (period: "day"|"week"|"month"|"all" = "week") => req(`/ratings?period=${period}`);
export const getLedger = (limit=50, offset=0) => req(`/points/ledger?limit=${limit}&offset=${offset}`);
export const getBanners = (position:string) => req(`/banners?position=${encodeURIComponent(position)}`);

// === Уведомления ===
export const getNotifications = () => req(`/notifications`);
export const markNotification = (id:number) => req(`/notifications/${id}/read`, { method:"POST" });
'

# ====== FRONTEND: Icon.tsx ======
write_file "${FRONTEND_DIR}/src/components/Icon.tsx" '
import React from "react";
type Props = { name:string; className?:string; style?:React.CSSProperties; };
export default function Icon({ name, className="", style }:Props){
  return <span className={`material-symbols-rounded ${className}`} style={style}>{name}</span>;
}
'

# ====== FRONTEND: Avatar.tsx ======
write_file "${FRONTEND_DIR}/src/components/Avatar.tsx" '
import React from "react";
import { DEFAULT_IMAGES } from "../config";
export default function Avatar({ src, size=32, alt="" }:{src?:string; size?:number; alt?:string;}){
  const s = { width:size, height:size, borderRadius:"50%", objectFit:"cover", border:"1px solid rgba(255,255,255,.2)" } as React.CSSProperties;
  return <img src={src || DEFAULT_IMAGES.avatar} alt={alt} style={s} loading="lazy" />;
}
'

# ====== FRONTEND: MediaGrid.tsx ======
write_file "${FRONTEND_DIR}/src/components/MediaGrid.tsx" '
import React from "react";
export default function MediaGrid({ urls=[], onClick }:{urls?:string[]; onClick?:(url:string)=>void;}){
  if (!urls.length) return null;
  return (
    <div style={{display:"grid", gridTemplateColumns:"repeat(3,1fr)", gap:8}}>
      {urls.map(u=>(
        <img key={u} src={u} alt="" style={{width:"100%", borderRadius:12, cursor:onClick?"pointer":"default"}} onClick={()=>onClick?.(u)} />
      ))}
    </div>
  );
}
'

# ====== FRONTEND: PointPinCard.tsx ======
write_file "${FRONTEND_DIR}/src/components/PointPinCard.tsx" '
import React from "react";
import MediaGrid from "./MediaGrid";
import Icon from "./Icon";
export default function PointPinCard({ point, onOpen }:{point:any; onOpen:(id:number)=>void;}){
  return (
    <div className="glass-card card" style={{minWidth:260}}>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:8}}>
        <div style={{fontWeight:600}}>{point.title || "Место"}</div>
        <button className="badge" onClick={()=>onOpen(point.id)}><Icon name="open_in_new" /> открыть</button>
      </div>
      <MediaGrid urls={point.photos||[]} onClick={()=>onOpen(point.id)} />
      <div style={{display:"flex",gap:8,marginTop:8,alignItems:"center"}}>
        <Icon name="location_on" /><span>{point.lat.toFixed(5)}, {point.lng.toFixed(5)}</span>
        {typeof point.catches_count==="number" && <span className="badge"><Icon name="bar_chart" /> {point.catches_count}</span>}
      </div>
    </div>
  );
}
'

# ====== FRONTEND: Header.tsx ======
write_file "${FRONTEND_DIR}/src/components/Header.tsx" '
import React from "react";
import Icon from "./Icon";
import Avatar from "./Avatar";
import { ICONS, DEFAULT_IMAGES } from "../config";

export default function Header({ points, onWeatherClick, onAlertsClick, onAddClick, profile }:{
  points?: number;
  onWeatherClick?: ()=>void;
  onAlertsClick?: ()=>void;
  onAddClick?: ()=>void;
  profile?: { name?:string; avatar?:string; points?:number };
}){
  return (
    <header className="header">
      <div className="header-inner" style={{justifyContent:"space-between"}}>
        <div style={{display:"flex",alignItems:"center",gap:10}}>
          <img src={DEFAULT_IMAGES.logo} alt="logo" height={28} />
          {!!points && <span className="badge"><Icon name="bolt" /> {points}</span>}
        </div>
        <div className="toolbar">
          <button className="badge" onClick={onWeatherClick}><Icon name={ICONS.header.weather} /> Погода</button>
          <button className="badge" onClick={onAlertsClick}><Icon name={ICONS.header.bell} /></button>
          <button className="badge" onClick={onAddClick}><Icon name={ICONS.header.add} /></button>
          <a className="badge" href="/profile"><Avatar src={profile?.avatar} size={28} /> Профиль</a>
        </div>
      </div>
    </header>
  );
}
'

# ====== FRONTEND: BottomNav.tsx ======
write_file "${FRONTEND_DIR}/src/components/BottomNav.tsx" '
import React from "react";
import Icon from "./Icon";
import { ICONS } from "../config";

const Item = ({href, name, label}:{href:string; name:string; label:string}) => (
  <a href={href} style={{flex:1, display:"flex", flexDirection:"column", alignItems:"center", gap:4, padding:"8px 0"}}>
    <Icon name={name} /><small>{label}</small>
  </a>
);

export default function BottomNav(){
  return (
    <footer className="bottom">
      <div className="bottom-inner" style={{justifyContent:"space-around"}}>
        <Item href="/feed" name={ICONS.bottom.feed} label="Лента" />
        <Item href="/map" name={ICONS.bottom.map} label="Карта" />
        <Item href="/add/catch" name={ICONS.bottom.addCatch} label="Улов" />
        <Item href="/add/place" name={ICONS.bottom.addPlace} label="Место" />
        <Item href="/alerts" name={ICONS.bottom.alerts} label="Уведомл." />
        <Item href="/profile" name={ICONS.bottom.profile} label="Профиль" />
      </div>
    </footer>
  );
}
'

# ====== FRONTEND: App.tsx ======
write_file "${FRONTEND_DIR}/src/App.tsx" '
import React from "react";
import Header from "./components/Header";
import BottomNav from "./components/BottomNav";
import "./styles/app.css";

function useRoute(){
  const [path, setPath] = React.useState(window.location.pathname);
  React.useEffect(()=>{
    const onPop = ()=>setPath(window.location.pathname);
    window.addEventListener("popstate", onPop);
    return ()=>window.removeEventListener("popstate", onPop);
  },[]);
  return path;
}

export default function App(){
  const path = useRoute();
  const goto = (p:string) => { if (p!==window.location.pathname){ window.history.pushState({}, "", p); window.dispatchEvent(new PopStateEvent("popstate")); } };
  const onWeatherClick = ()=>goto("/weather");
  const onAlertsClick = ()=>goto("/alerts");
  const onAddClick = ()=>goto("/add/catch");

  // лениво грузим страницы
  const Page = React.useMemo(()=>{
    if (path.startsWith("/map")) return React.lazy(()=>import("./pages/MapScreen"));
    if (path.startsWith("/add/catch")) return React.lazy(()=>import("./pages/AddCatchPage"));
    if (path.startsWith("/add/place")) return React.lazy(()=>import("./pages/AddPlacePage"));
    if (path.startsWith("/catch/")) return React.lazy(()=>import("./pages/CatchDetailPage"));
    if (path.startsWith("/place/")) return React.lazy(()=>import("./pages/PlaceDetailPage"));
    if (path.startsWith("/alerts")) return React.lazy(()=>import("./pages/NotificationsPage"));
    if (path.startsWith("/profile")) return React.lazy(()=>import("./pages/ProfilePage"));
    if (path.startsWith("/weather")) return React.lazy(()=>import("./pages/WeatherPage"));
    return React.lazy(()=>import("./pages/FeedScreen"));
  },[path]);

  return (
    <div className="app-shell">
      <Header onWeatherClick={onWeatherClick} onAlertsClick={onAlertsClick} onAddClick={onAddClick} />
      <React.Suspense fallback={<div style={{padding:12}}>Загрузка...</div>}>
        <Page />
      </React.Suspense>
      <BottomNav />
    </div>
  );
}
'

# ====== FRONTEND: main.tsx ======
write_file "${FRONTEND_DIR}/src/main.tsx" '
import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
createRoot(document.getElementById("root")!).render(<App />);
'

# ====== FRONTEND: страницы ======

# FeedScreen.tsx
write_file "${FRONTEND_DIR}/src/pages/FeedScreen.tsx" '
import React from "react";
import { getFeed, getBanners } from "../api";
import Icon from "../components/Icon";
import Avatar from "../components/Avatar";

export default function FeedScreen(){
  const [items, setItems] = React.useState<any[]>([]);
  const [banner, setBanner] = React.useState<any|null>(null);

  React.useEffect(()=>{
    getFeed(10,0).then(setItems).catch(console.error);
    getBanners("feed_top").then((b:any[])=>setBanner(b[0]||null)).catch(()=>{});
  },[]);

  const open = (id:number) => { window.history.pushState({}, "", `/catch/${id}`); window.dispatchEvent(new PopStateEvent("popstate")); };

  return (
    <div style={{padding:12}}>
      {banner && <a href={banner.url}><img src={banner.image} alt="" style={{width:"100%",borderRadius:12,marginBottom:12}}/></a>}
      {items.map(x=>(
        <div key={x.id} className="glass-card card" style={{marginBottom:12}}>
          <div style={{display:"flex",gap:8,alignItems:"center",marginBottom:8}}>
            <Avatar src={x.user_avatar} />
            <div style={{fontWeight:600}}>{x.user_name}</div>
            <span className="badge" style={{marginLeft:"auto"}}>{new Date(x.created_at).toLocaleString()}</span>
          </div>
          {x.media_url && <img src={x.media_url} alt="" style={{width:"100%",borderRadius:12}} onClick={()=>open(x.id)} />}
          {x.caption && <div style={{marginTop:8}}>{x.caption}</div>}
          <div className="toolbar" style={{marginTop:8}}>
            <button className="badge"><Icon name="favorite" /> {x.likes_count}</button>
            <button className="badge"><Icon name="mode_comment" /> {x.comments_count}</button>
            <button className="badge" style={{marginLeft:"auto"}} onClick={()=>open(x.id)}><Icon name="open_in_new" /> Открыть</button>
          </div>
        </div>
      ))}
    </div>
  );
}
'

# MapScreen.tsx (Leaflet + сохранение локации в Погоду)
write_file "${FRONTEND_DIR}/src/pages/MapScreen.tsx" '
import React from "react";
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";
import { getPoints, getWeather, getWeatherFavs, saveWeatherFav } from "../api";
import type { Point } from "../types";
import PointPinCard from "../components/PointPinCard";
import { TILES_URL } from "../config";

const icon = L.icon({ iconUrl:"https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png", iconSize:[25,41], iconAnchor:[12,41], popupAnchor:[1,-34], shadowUrl:"https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png" });

function ClickToSave(){
  useMapEvents({
    click(e){
      const lat = e.latlng.lat; const lng = e.latlng.lng;
      const id = `${lat.toFixed(5)},${lng.toFixed(5)}`;
      const name = `Место ${lat.toFixed(3)}, ${lng.toFixed(3)}`;
      saveWeatherFav({ id, name, lat, lng });
      alert("Локация сохранена в Погоду");
    }
  });
  return null;
}

export default function MapScreen(){
  const [points, setPoints] = React.useState<Point[]>([]);
  const [center] = React.useState<[number,number]>([55.75,37.62]);

  React.useEffect(()=>{
    getPoints({ limit:500 }).then((r:any)=>setPoints(Array.isArray(r)? r : (r?.data||[]))).catch(console.error);
  },[]);

  const openPlace = (id:number) => {
    window.history.pushState({}, "", `/place/${id}`);
    window.dispatchEvent(new PopStateEvent("popstate"));
  };

  return (
    <div className="map-wrap">
      <div className="map-overlay">
        <div className="glass-card card" style={{flex:1}}>
          <b>Карта</b> — клик по карте сохранит локацию в раздел «Погода».  
          <div style={{marginTop:6}} className="badge">Добавить точки/уловы — кнопки снизу.</div>
        </div>
      </div>
      <MapContainer center={center} zoom={10} scrollWheelZoom style={{height:"100%", width:"100%"}}>
        <TileLayer url={TILES_URL} />
        <ClickToSave />
        {points.map(p=>(
          <Marker key={p.id} position={[p.lat,p.lng]} icon={icon}>
            <Popup>
              <PointPinCard point={p} onOpen={openPlace} />
            </Popup>
          </Marker>
        ))}
      </MapContainer>
      <a className="map-fab" href="/add/place" title="Добавить место">+</a>
    </div>
  );
}
'

# CatchDetailPage.tsx
write_file "${FRONTEND_DIR}/src/pages/CatchDetailPage.tsx" '
import React from "react";
import { getCatchById, addComment } from "../api";
import Icon from "../components/Icon";
import Avatar from "../components/Avatar";

export default function CatchDetailPage(){
  const id = Number(window.location.pathname.split("/").pop());
  const [data, setData] = React.useState<any|null>(null);
  const [text, setText] = React.useState("");

  React.useEffect(()=>{ getCatchById(id).then(setData).catch(console.error); },[id]);

  const submit = async (e:any)=>{ e.preventDefault(); if(!text.trim()) return;
    try{ await addComment(id,{text}); setText(""); const fresh = await getCatchById(id); setData(fresh); }catch(e){console.error(e);}
  };

  if(!data) return <div style={{padding:12}}>Загрузка...</div>;
  return (
    <div style={{padding:12}}>
      <div className="glass-card card">
        <div style={{display:"flex",gap:8,alignItems:"center",marginBottom:8}}>
          <Avatar src={data.user_avatar} />
          <div style={{fontWeight:600}}>{data.user_name}</div>
          <span className="badge" style={{marginLeft:"auto"}}>{new Date(data.created_at).toLocaleString()}</span>
        </div>
        {data.media_url && <img src={data.media_url} alt="" style={{width:"100%",borderRadius:12}} />}
        {data.caption && <div style={{marginTop:8}}>{data.caption}</div>}
        <div className="toolbar" style={{marginTop:8}}>
          <button className="badge"><Icon name="favorite" /> {data.likes_count}</button>
          <button className="badge"><Icon name="share" /> Поделиться</button>
        </div>
      </div>

      <form onSubmit={submit} style={{marginTop:12}} className="glass-card card">
        <div style={{display:"flex",gap:8}}>
          <input placeholder="Написать комментарий..." value={text} onChange={e=>setText(e.target.value)} />
          <button className="badge" type="submit"><Icon name="send" /> Отправить</button>
        </div>
      </form>
    </div>
  );
}
'

# AddCatchPage.tsx
write_file "${FRONTEND_DIR}/src/pages/AddCatchPage.tsx" '
import React from "react";
import { addCatch, getWeather } from "../api";

export default function AddCatchPage(){
  const [lat, setLat] = React.useState<number>(55.75);
  const [lng, setLng] = React.useState<number>(37.62);
  const [dt, setDt] = React.useState<string>(new Date().toISOString().slice(0,16));
  const [species, setSpecies] = React.useState("");
  const [caption, setCaption] = React.useState("");
  const [photo, setPhoto] = React.useState("");
  const [weather, setWeather] = React.useState<any|null>(null);

  const fetchWeather = async ()=>{
    const unix = Math.floor(new Date(dt).getTime()/1000);
    try{ const w = await getWeather(lat, lng, unix); setWeather(w); }catch(e){ setWeather(null); }
  };

  const submit = async (e:any)=>{ e.preventDefault();
    const payload:any = { lat, lng, caught_at: new Date(dt).toISOString().replace("Z",""), species, notes: caption, photo_url:photo, weather: weather||null };
    await addCatch(payload);
    alert("Улов добавлен");
    window.history.pushState({}, "", "/feed"); window.dispatchEvent(new PopStateEvent("popstate"));
  };

  return (
    <div style={{padding:12}}>
      <form onSubmit={submit} className="glass-card card">
        <h3>Добавить улов</h3>
        <div className="row">
          <div><label>Широта</label><input type="number" value={lat} onChange={e=>setLat(parseFloat(e.target.value))} step="0.00001" /></div>
          <div><label>Долгота</label><input type="number" value={lng} onChange={e=>setLng(parseFloat(e.target.value))} step="0.00001" /></div>
        </div>
        <div className="row">
          <div><label>Дата и время</label><input type="datetime-local" value={dt} onChange={e=>setDt(e.target.value)} /></div>
          <div><label>Вид рыбы</label><input value={species} onChange={e=>setSpecies(e.target.value)} /></div>
        </div>
        <div><label>Фото (URL)</label><input value={photo} onChange={e=>setPhoto(e.target.value)} /></div>
        <div><label>Описание</label><textarea value={caption} onChange={e=>setCaption(e.target.value)} rows={3} /></div>
        <div className="toolbar" style={{marginTop:8}}>
          <button className="badge" type="button" onClick={fetchWeather}>Подтянуть погоду</button>
          <button className="badge" type="submit" style={{marginLeft:"auto"}}>Сохранить</button>
        </div>
        {weather && <div className="badge" style={{marginTop:8}}>Погода сохранена</div>}
      </form>
    </div>
  );
}
'

# AddPlacePage.tsx
write_file "${FRONTEND_DIR}/src/pages/AddPlacePage.tsx" '
import React from "react";
import { addPoint } from "../api";

export default function AddPlacePage(){
  const [title, setTitle] = React.useState("");
  const [lat, setLat] = React.useState<number>(55.75);
  const [lng, setLng] = React.useState<number>(37.62);
  const [photos, setPhotos] = React.useState("");

  const submit = async (e:any)=>{ e.preventDefault();
    const payload = { title, lat, lng, photos: photos.split(",").map(x=>x.trim()).filter(Boolean) };
    await addPoint(payload);
    alert("Место добавлено");
    window.history.pushState({}, "", "/map"); window.dispatchEvent(new PopStateEvent("popstate"));
  };

  return (
    <div style={{padding:12}}>
      <form onSubmit={submit} className="glass-card card">
        <h3>Добавить место</h3>
        <div><label>Название</label><input value={title} onChange={e=>setTitle(e.target.value)} /></div>
        <div className="row">
          <div><label>Широта</label><input type="number" step="0.00001" value={lat} onChange={e=>setLat(parseFloat(e.target.value))}/></div>
          <div><label>Долгота</label><input type="number" step="0.00001" value={lng} onChange={e=>setLng(parseFloat(e.target.value))}/></div>
        </div>
        <div><label>Фото (через запятую, URL)</label><input value={photos} onChange={e=>setPhotos(e.target.value)} /></div>
        <div className="toolbar" style={{marginTop:8}}>
          <button className="badge" type="submit" style={{marginLeft:"auto"}}>Сохранить</button>
        </div>
      </form>
    </div>
  );
}
'

# NotificationsPage.tsx
write_file "${FRONTEND_DIR}/src/pages/NotificationsPage.tsx" '
import React from "react";
import { getNotifications, markNotification } from "../api";
import Icon from "../components/Icon";

export default function NotificationsPage(){
  const [items,setItems] = React.useState<any[]>([]);
  React.useEffect(()=>{ getNotifications().then(setItems).catch(console.error); },[]);
  const mark = async(id:number)=>{ try{ await markNotification(id); setItems(s=>s.map(x=>x.id===id? {...x, read:true}:x)) }catch(e){console.error(e)} };
  return (
    <div style={{padding:12}}>
      <h3 style={{marginBottom:8}}>Уведомления</h3>
      {items.map(x=>(
        <div key={x.id} className="glass-card card" style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:8}}>
          <div>
            <div style={{fontWeight:600}}>{x.title}</div>
            <div style={{opacity:.8}}>{x.body}</div>
          </div>
          <button className="badge" onClick={()=>mark(x.id)} disabled={x.read}><Icon name="done" /> {x.read? "Прочитано":"Отметить"}</button>
        </div>
      ))}
      {!items.length && <div className="glass-card card">Пока пусто</div>}
    </div>
  );
}
'

# ProfilePage.tsx (авторизация front)
write_file "${FRONTEND_DIR}/src/pages/ProfilePage.tsx" '
import React from "react";
import { me, login, logout, getLedger } from "../api";
import Avatar from "../components/Avatar";
import Icon from "../components/Icon";

export default function ProfilePage(){
  const [profile,setProfile] = React.useState<any|null>(null);
  const [email,setEmail] = React.useState(""); const [password,setPassword] = React.useState("");
  const [ledger,setLedger] = React.useState<any[]>([]);

  const load = async()=>{
    try{
      const p = await me(); setProfile(p);
      const l = await getLedger(20,0); setLedger(l?.items||l||[]);
    }catch{ setProfile(null); }
  };
  React.useEffect(()=>{ load(); },[]);

  const doLogin = async(e:any)=>{ e.preventDefault(); await login(email,password); await load(); };
  const doLogout = async()=>{ await logout(); setProfile(null); };

  if(!profile){
    return (
      <div style={{padding:12}}>
        <form onSubmit={doLogin} className="glass-card card" style={{maxWidth:420, margin:"0 auto"}}>
          <h3>Вход</h3>
          <div><label>E-mail</label><input value={email} onChange={e=>setEmail(e.target.value)}/></div>
          <div><label>Пароль</label><input type="password" value={password} onChange={e=>setPassword(e.target.value)}/></div>
          <div className="toolbar" style={{marginTop:8}}>
            <button className="badge" type="submit" style={{marginLeft:"auto"}}>Войти</button>
          </div>
        </form>
      </div>
    );
  }

  return (
    <div style={{padding:12, display:"grid", gap:12}}>
      <div className="glass-card card" style={{display:"flex",gap:12,alignItems:"center"}}>
        <Avatar src={profile.avatar} size={56} />
        <div style={{fontSize:18, fontWeight:700}}>{profile.name}</div>
        <span className="badge" style={{marginLeft:"auto"}}><Icon name="bolt" /> {profile.points} баллов</span>
        <button className="badge" onClick={doLogout}>Выйти</button>
      </div>

      <div className="glass-card card">
        <h4 style={{marginTop:0}}>Бонусы (ledger)</h4>
        {ledger.map((x:any)=>(
          <div key={x.id} style={{display:"flex",gap:8,alignItems:"center",padding:"6px 0", borderBottom:"1px solid rgba(255,255,255,.08)"}}>
            <span className="badge">{new Date(x.created_at).toLocaleString()}</span>
            <div style={{flex:1}}>{x.reason}</div>
            <b style={{color:x.delta>0?"#4ade80":"#f87171"}}>{x.delta>0? "+":""}{x.delta}</b>
            <span className="badge">Баланс: {x.balance}</span>
          </div>
        ))}
        {!ledger.length && <div>Нет начислений</div>}
      </div>
    </div>
  );
}
'

# WeatherPage.tsx
write_file "${FRONTEND_DIR}/src/pages/WeatherPage.tsx" '
import React from "react";
import { getWeatherFavs, getWeather } from "../api";
import Icon from "../components/Icon";

export default function WeatherPage(){
  const [favs,setFavs] = React.useState(getWeatherFavs());
  const [data,setData] = React.useState<Record<string, any>>({});

  React.useEffect(()=>{
    (async()=>{
      const out:Record<string,any> = {};
      for (const f of favs){
        try{ out[f.id] = await getWeather(f.lat, f.lng); }catch{ out[f.id] = {error:true}; }
      }
      setData(out);
    })();
  },[favs]);

  return (
    <div style={{padding:12, display:"grid", gap:12}}>
      {favs.map(f=>(
        <div key={f.id} className="glass-card card" style={{display:"flex",gap:12,alignItems:"center"}}>
          <div style={{flex:1}}>
            <b>{f.name}</b><div style={{opacity:.8}}>{f.lat.toFixed(3)}, {f.lng.toFixed(3)}</div>
          </div>
          <div style={{textAlign:"right"}}>
            {!data[f.id]?.error ? (
              <>
                <div><Icon name="device_thermostat" /> {Math.round(data[f.id]?.temp ?? data[f.id]?.main?.temp ?? 0)}°</div>
                <div><Icon name="air" /> {Math.round(data[f.id]?.wind ?? data[f.id]?.wind?.speed ?? 0)} м/с</div>
              </>
            ) : <span className="badge">нет данных</span>}
          </div>
        </div>
      ))}
      {!favs.length && <div className="glass-card card">Добавляйте локации кликом на карте</div>}
    </div>
  );
}
'

# PlaceDetailPage.tsx
write_file "${FRONTEND_DIR}/src/pages/PlaceDetailPage.tsx" '
import React from "react";
import { getPlaceById } from "../api";
import MediaGrid from "../components/MediaGrid";

export default function PlaceDetailPage(){
  const id = Number(window.location.pathname.split("/").pop());
  const [data,setData] = React.useState<any|null>(null);
  React.useEffect(()=>{ getPlaceById(id).then(setData).catch(console.error); },[id]);

  if(!data) return <div style={{padding:12}}>Загрузка...</div>;
  return (
    <div style={{padding:12}}>
      <div className="glass-card card">
        <h3 style={{marginTop:0}}>{data.title||"Место"}</h3>
        <div style={{opacity:.8, marginBottom:8}}>{data.lat?.toFixed(5)}, {data.lng?.toFixed(5)}</div>
        <MediaGrid urls={data.photos||[]} />
        {typeof data.catches_count==="number" && <div className="badge" style={{marginTop:8}}>Уловов: {data.catches_count}</div>}
      </div>
    </div>
  );
}
'

# ====== BACKEND: CORS фиксы (middleware + config) ======

# app/Http/Middleware/CorsAll.php
write_file "${BACKEND_DIR}/app/Http/Middleware/CorsAll.php" '
<?php
namespace App\Http\Middleware;
use Closure;

class CorsAll {
  public function handle($request, Closure $next){
    $response = $next($request);
    $origin = $request->headers->get("Origin");
    $allowed = env("CORS_ALLOWED_ORIGINS", "");
    $ok = $allowed==="*" || ($origin && in_array($origin, array_map("trim", explode(",", $allowed))));
    if ($ok) {
      $response->headers->set("Access-Control-Allow-Origin", $origin ?: "*");
      $response->headers->set("Vary", "Origin");
      $response->headers->set("Access-Control-Allow-Credentials", "true");
      $response->headers->set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
      $response->headers->set("Access-Control-Allow-Headers", "*, Authorization, Content-Type, X-Requested-With");
    }
    if ($request->getMethod()==="OPTIONS") {
      $response->setStatusCode(204);
    }
    return $response;
  }
}
'

# config/cors.php
write_file "${BACKEND_DIR}/config/cors.php" '
<?php
return [
  "paths" => ["api/*", "*"],
  "allowed_methods" => ["*"],
  "allowed_origins" => explode(",", env("CORS_ALLOWED_ORIGINS", "https://www.fishtrackpro.ru")),
  "allowed_headers" => ["*"],
  "exposed_headers" => [],
  "max_age" => 0,
  "supports_credentials" => true,
];
'

# Регистрация middleware в Kernel (делаем аккуратную вставку; если уже есть — ок)
KERNEL="${BACKEND_DIR}/app/Http/Kernel.php"
if [ -f "$KERNEL" ]; then
  echo "→ Регистрирую CorsAll middleware"
  if ! grep -q "App\\Http\\Middleware\\CorsAll::class" "$KERNEL"; then
    tmp="${KERNEL}.tmp"
    awk '
      BEGIN{done=0}
      /protected \$middleware\s*=\s*\[/ && !done {
        print; print "        \\App\\Http\\Middleware\\CorsAll::class,";
        done=1; next
      }
      {print}
    ' "$KERNEL" > "$tmp" && mv "$tmp" "$KERNEL"
  fi
else
  echo "⚠️ Kernel.php не найден — пропустил регистрацию."
fi

# ====== .env рекомендация ======
ENV="${BACKEND_DIR}/.env"
if [ -f "$ENV" ]; then
  echo "→ Устанавливаю CORS_ALLOWED_ORIGINS в .env (если не задан)"
  if ! grep -q "^CORS_ALLOWED_ORIGINS=" "$ENV"; then
    echo "CORS_ALLOWED_ORIGINS=${PUBLIC_SITE}" >> "$ENV"
  fi
fi

echo "✅ Готово. Пересобери фронт: (cd ${FRONTEND_DIR} && npm i && npm run build) и перезапусти backend."
echo "Если CORS ещё ругается — проверь nginx headers и что API отдаёт Access-Control-Allow-Origin с правильным Origin."