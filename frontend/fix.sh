#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
SRC="$ROOT/src"

mkdir -p "$SRC/screens" "$SRC/components" "$SRC/data" "$SRC/config" "$SRC/styles"

# 0) Напоминание об установке зависимостей (react-router-dom)
echo ">>> ВНИМАНИЕ: после скрипта запусти:  npm i react-router-dom"

########################################
# 1) Icon + UI config (если ещё нет)
########################################
cat > "$SRC/config/ui.ts" <<'TS'
export const ASSETS = {
  logo: "/assets/logo.svg",
  defaultAvatar: "/assets/default-avatar.png",
  bgPattern: "/assets/bg-pattern.png",
};

export const ICONS = {
  map: "map",
  feed: "dynamic_feed",
  alerts: "notifications",
  profile: "account_circle",
  plus: "add",
  like: "favorite",
  comment: "mode_comment",
  share: "ios_share",
  back: "arrow_back",
  settings: "settings",
  friends: "group",
  rating: "military_tech",
  weather: "sunny",
  location: "location_on",
  edit: "edit",
  logout: "logout",
  check: "check",
  photo: "photo_camera",
  video: "videocam",
  place: "bookmark_added",
  pin: "place",
} as const;
TS

cat > "$SRC/components/Icon.tsx" <<'TSX'
import React from "react";
import { ICONS } from "../config/ui";

type Props = {
  name: keyof typeof ICONS | string;
  className?: string;
  size?: number;
  weight?: number;
  grade?: number;
  fill?: 0|1;
  title?: string;
};

export default function Icon({ name, className="", size=24, weight=400, grade=0, fill=0, title }: Props){
  const glyph = (ICONS as any)[name] ?? name;
  return (
    <span
      className={`material-symbols-rounded ${className}`}
      style={{ fontSize: size, fontVariationSettings: `'FILL' ${fill}, 'wght' ${weight}, 'GRAD' ${grade}, 'opsz' ${Math.max(20, size)}` }}
      aria-label={title || (typeof name === "string" ? name : "")}
      title={title}
    >
      {glyph}
    </span>
  );
}
TSX

cat > "$SRC/styles/ui.css" <<'CSS'
@import url('https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,GRAD,FILL@20..48,100..700,-50..200,0..1');

.material-symbols-rounded {
  font-family: 'Material Symbols Rounded';
  font-weight: normal; font-style: normal; font-size: 24px;
  line-height: 1; letter-spacing: normal; text-transform: none;
  display: inline-block; white-space: nowrap; word-wrap: normal;
  direction: ltr;
  -webkit-font-feature-settings: 'liga'; -webkit-font-smoothing: antialiased;
}

.z-header { z-index: 40; }
.z-fab { z-index: 35; }
.z-bottomnav { z-index: 30; }
.z-map-popover { z-index: 28; }
.z-map { z-index: 10; }
CSS

########################################
# 2) BrowserRouter: main.tsx
########################################
# Создадим main.tsx если его нет, иначе перезапишем безопасно
cat > "$SRC/main.tsx" <<'TSX'
import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import "./styles/ui.css";
import "./index.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <BrowserRouter basename="/">
      <App/>
    </BrowserRouter>
  </React.StrictMode>
);
TSX

########################################
# 3) Обновлённый BottomNav с NavLink
########################################
cat > "$SRC/components/BottomNav.tsx" <<'TSX'
import React from "react";
import { NavLink, useLocation, useNavigate } from "react-router-dom";
import Icon from "./Icon";

export default function BottomNav({ onFab }:{ onFab?: ()=>void }){
  const nav = useNavigate();
  const loc = useLocation();

  const Fab = () => (
    <div className="absolute left-0 right-0 bottom-8 flex justify-center pointer-events-none">
      <button
        className="pointer-events-auto rounded-full w-14 h-14 flex items-center justify-center shadow-lg bg-black text-white"
        onClick={()=>{
          if (loc.pathname.startsWith("/feed")) nav("/add-catch");
          else nav("/add-place");
        }}
        aria-label="Добавить"
      >
        <Icon name="plus" />
      </button>
    </div>
  );

  const Item = ({to, label, icon}:{to:string; label:string; icon:string}) => (
    <NavLink
      to={to}
      className={({isActive})=>`flex flex-col items-center flex-1 py-2 ${isActive ? "text-black" : "text-gray-500"}`}
    >
      <Icon name={icon} />
      <span className="text-[11px] mt-0.5">{label}</span>
    </NavLink>
  );

  return (
    <div className="z-bottomnav fixed bottom-0 left-0 right-0">
      <div className="mx-auto max-w-md relative">
        <Fab/>
        <div className="rounded-t-2xl backdrop-blur bg-white/70 border-t border-white/50 shadow flex">
          <Item to="/map" label="Карта" icon="map" />
          <Item to="/feed" label="Лента" icon="feed" />
          <div className="w-14" />
          <Item to="/alerts" label="Оповещения" icon="alerts" />
          <Item to="/profile" label="Профиль" icon="profile" />
        </div>
      </div>
    </div>
  );
}
TSX

########################################
# 4) Страницы: Друзья, Рейтинги, Настройки, Мои уловы
########################################
cat > "$SRC/screens/FriendsPage.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";

type Friend = { id:number; name:string; handle?:string; avatar?:string; followed?:boolean; };

async function fetchFriends(): Promise<Friend[]>{
  try{
    const base = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
    const r = await fetch(`${base}/friends`, { credentials:"include" });
    if(!r.ok) return [];
    const j = await r.json();
    return j?.items || [];
  }catch{ return []; }
}

export default function FriendsPage(){
  const [items,setItems]=useState<Friend[]>([]);
  const [loading,setLoading]=useState(true);
  useEffect(()=>{ fetchFriends().then(d=>{setItems(d);setLoading(false);}); },[]);
  if(loading) return <div className="p-4 text-gray-500">Загрузка…</div>;
  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="friends"/><div className="font-semibold">Друзья</div>
      </div>
      <ul className="divide-y divide-gray-100">
        {items.map(f=>(
          <li key={f.id} className="p-3 flex items-center gap-3">
            <img src={f.avatar||"/assets/default-avatar.png"} className="w-10 h-10 rounded-full object-cover" />
            <div className="flex-1">
              <div className="font-medium">{f.name}</div>
              <div className="text-xs text-gray-500">@{f.handle||("user"+f.id)}</div>
            </div>
            <a href={`/u/${f.id}`} className="text-sm text-blue-600 hover:underline">Профиль</a>
          </li>
        ))}
      </ul>
    </div>
  );
}
TSX

cat > "$SRC/screens/RatingsPage.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";

type Row={ user_id:number; name:string; handle?:string; avatar?:string; score:number; rank:number; };

async function fetchRatings(): Promise<Row[]>{
  try{
    const base = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
    const r = await fetch(`${base}/ratings`, { credentials:"include" });
    if(!r.ok) return [];
    const j = await r.json();
    return j?.items || [];
  }catch{ return []; }
}

export default function RatingsPage(){
  const [items,setItems]=useState<Row[]>([]);
  useEffect(()=>{ fetchRatings().then(setItems); },[]);
  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center justify-between">
        <div className="flex items-center gap-2"><Icon name="rating"/><div className="font-semibold">Рейтинги</div></div>
        <a href="/profile" className="text-sm text-blue-600">Мой профиль</a>
      </div>
      <div className="p-3">
        {items.map(row=>(
          <a href={`/u/${row.user_id}`} key={row.user_id} className="flex items-center gap-3 p-3 mb-2 rounded-xl bg-white/70 backdrop-blur border border-white/40 hover:bg-white/90">
            <div className="w-8 text-center font-semibold">{row.rank}</div>
            <img src={row.avatar||"/assets/default-avatar.png"} className="w-10 h-10 rounded-full object-cover"/>
            <div className="flex-1">
              <div className="font-medium">{row.name}</div>
              <div className="text-xs text-gray-500">@{row.handle||("user"+row.user_id)}</div>
            </div>
            <div className="text-sm font-semibold">{row.score}</div>
          </a>
        ))}
      </div>
    </div>
  );
}
TSX

cat > "$SRC/screens/SettingsPage.tsx" <<'TSX'
import React from "react";
import Icon from "../components/Icon";

export default function SettingsPage(){
  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="settings"/><div className="font-semibold">Настройки</div>
      </div>
      <div className="p-4 space-y-3">
        <a className="block p-3 rounded-xl bg-white/70 border border-white/50" href="/agreements">Пользовательское соглашение</a>
        <a className="block p-3 rounded-xl bg-white/70 border border-white/50" href="/privacy">Политика конфиденциальности</a>
        <a className="block p-3 rounded-xl bg-white/70 border border-white/50" href="/logout">Выйти</a>
      </div>
    </div>
  );
}
TSX

cat > "$SRC/screens/MyCatchesPage.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";

type CatchItem={ id:number; species?:string; media_url?:string; created_at:string; likes_count?:number; comments_count?:number; };

async function fetchMy(): Promise<CatchItem[]>{
  try{
    const base = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
    const r = await fetch(`${base}/catches?me=1&limit=50`, { credentials:"include" });
    if(!r.ok) return [];
    const j = await r.json();
    return j?.items || [];
  }catch{ return []; }
}

export default function MyCatchesPage(){
  const [items,setItems]=useState<CatchItem[]>([]);
  useEffect(()=>{ fetchMy().then(setItems); },[]);
  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="photo"/><div className="font-semibold">Мои уловы</div>
      </div>
      <div className="p-3 grid grid-cols-2 gap-3">
        {items.map(it=>(
          <a key={it.id} href={`/catch/${it.id}`} className="block rounded-xl overflow-hidden bg-white/70 border border-white/50">
            {it.media_url ? (
              <img src={it.media_url} className="w-full aspect-square object-cover"/>
            ) : (
              <div className="w-full aspect-square flex items-center justify-center text-gray-400"><Icon name="photo"/></div>
            )}
            <div className="p-2 text-sm flex items-center justify-between">
              <span>{it.species||"Не указано"}</span>
              <span className="text-gray-500 inline-flex items-center gap-2">
                <span className="inline-flex items-center gap-1"><Icon name="like" size={18}/>{it.likes_count||0}</span>
                <span className="inline-flex items-center gap-1"><Icon name="comment" size={18}/>{it.comments_count||0}</span>
              </span>
            </div>
          </a>
        ))}
      </div>
    </div>
  );
}
TSX

########################################
# 5) Обновляем App.tsx под Router c маршрутами без #
########################################
cat > "$SRC/App.tsx" <<'TSX'
import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import BottomNav from "./components/BottomNav";
import MapScreen from "./screens/MapScreen";
import FeedScreen from "./screens/FeedScreen";
import NotificationsPage from "./screens/NotificationsPage";
import ProfilePage from "./screens/ProfilePage";
import FriendsPage from "./screens/FriendsPage";
import RatingsPage from "./screens/RatingsPage";
import SettingsPage from "./screens/SettingsPage";
import MyCatchesPage from "./screens/MyCatchesPage";
import AddCatchPage from "./screens/AddCatchPage";
import AddPlacePage from "./screens/AddPlacePage";
import CatchDetailPage from "./screens/CatchDetailPage";
import PlaceDetailPage from "./screens/PlaceDetailPage";
import WeatherPage from "./screens/WeatherPage";

export default function App(){
  return (
    <div className="relative w-full h-screen bg-gray-50">
      <Routes>
        <Route path="/" element={<Navigate to="/map" replace/>} />
        <Route path="/map" element={<MapScreen/>} />
        <Route path="/feed" element={<FeedScreen/>} />
        <Route path="/alerts" element={<NotificationsPage/>} />
        <Route path="/profile" element={<ProfilePage/>} />
        <Route path="/friends" element={<FriendsPage/>} />
        <Route path="/ratings" element={<RatingsPage/>} />
        <Route path="/settings" element={<SettingsPage/>} />
        <Route path="/my-catches" element={<MyCatchesPage/>} />
        <Route path="/add-catch" element={<AddCatchPage/>} />
        <Route path="/add-place" element={<AddPlacePage/>} />
        <Route path="/catch/:id" element={<CatchDetailPage/>} />
        <Route path="/place/:id" element={<PlaceDetailPage/>} />
        <Route path="/weather" element={<WeatherPage/>} />
        <Route path="*" element={<Navigate to="/map" replace/>}/>
      </Routes>

      <BottomNav/>
    </div>
  );
}
TSX

########################################
# 6) API хелперы: дополним безопасно
########################################
cat > "$SRC/data/api.ts" <<'TS'
const BASE = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";

async function http<T=any>(path: string, init?: RequestInit): Promise<T>{
  const r = await fetch(`${BASE}${path}`, { credentials: "include", ...init });
  if(!r.ok) throw new Error(String(r.status));
  return r.json();
}

export const api = {
  // карта/точки
  points: (params:string)=> http(`/map/points${params}`),
  placeById: (id:number|string)=> http(`/map/points/${id}`),
  addPlace: (payload:any)=> http(`/points`, { method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify(payload) }),

  // лента/уловы
  feed: (params:string)=> http(`/feed${params}`),
  catchById: (id:number|string)=> http(`/catch/${id}`),
  addCatch: (payload:any)=> http(`/catches`, { method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify(payload) }),
  addComment: (id:number|string, body:string)=> http(`/catch/${id}/comments`, { method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify({ body }) }),
  toggleLike: (id:number|string)=> http(`/catch/${id}/like`, { method:"POST" }),

  // медиа/погода
  upload: (form:FormData)=> fetch(`${BASE}/upload`, { method:"POST", body: form, credentials:"include" }).then(r=>{ if(!r.ok) throw new Error(String(r.status)); return r.json(); }),
  weather: (lat:number, lng:number, dt?:number)=> http(`/weather?lat=${lat}&lng=${lng}${dt?`&dt=${dt}`:''}`),

  // профиль/друзья/рейтинги/уведомления
  me: ()=> http(`/profile/me`),
  friends: ()=> http(`/friends`),
  ratings: ()=> http(`/ratings`),
  notifications: ()=> http(`/notifications`),
};

export default api;
TS

########################################
# 7) Доработка FeedScreen: иконки/ссылки без #
########################################
cat > "$SRC/screens/FeedScreen.tsx" <<'TSX'
import React, { useEffect, useRef, useState } from "react";
import api from "../data/api";
import Icon from "../components/Icon";

type FeedItem = {
  id:number; user_id:number; user_name:string; user_avatar?:string;
  species?:string; media_url?:string; created_at:string;
  likes_count?:number; comments_count?:number;
};

export default function FeedScreen(){
  const [items,setItems]=useState<FeedItem[]>([]);
  const [offset,setOffset]=useState(0);
  const [loading,setLoading]=useState(false);
  const [done,setDone]=useState(false);
  const sentinel = useRef<HTMLDivElement|null>(null);

  async function load(){
    if(loading||done) return;
    setLoading(true);
    try{
      const j:any = await api.feed(`?limit=10&offset=${offset}`);
      const list:FeedItem[] = j?.items || [];
      setItems(prev=>[...prev, ...list]);
      setOffset(prev=>prev+list.length);
      if(list.length<10) setDone(true);
    } finally {
      setLoading(false);
    }
  }

  useEffect(()=>{ load(); },[]);
  useEffect(()=>{
    const el = sentinel.current; if(!el) return;
    const io = new IntersectionObserver(([e])=> { if(e.isIntersecting) load(); }, {rootMargin:"200px"});
    io.observe(el); return ()=>io.disconnect();
  },[sentinel.current, loading, done]);

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center justify-between">
        <div className="font-semibold">Лента</div>
        <a href="/weather" className="text-sm inline-flex items-center gap-1"><Icon name="weather"/> Погода</a>
      </div>

      <div className="divide-y divide-gray-100">
        {items.map(it=>(
          <article key={it.id} className="p-3 space-y-2">
            <header className="flex items-center gap-2">
              <img src={it.user_avatar||"/assets/default-avatar.png"} className="w-8 h-8 rounded-full object-cover"/>
              <a href={`/u/${it.user_id}`} className="font-medium hover:underline">{it.user_name}</a>
              <span className="text-xs text-gray-500 ml-auto">{new Date(it.created_at).toLocaleString()}</span>
            </header>
            <a href={`/catch/${it.id}`} className="block rounded-2xl overflow-hidden bg-white/70 border border-white/50">
              {it.media_url ? (
                <img src={it.media_url} className="w-full object-cover max-h-[70vh]" />
              ) : (
                <div className="w-full aspect-video flex items-center justify-center text-gray-400"><Icon name="photo"/></div>
              )}
            </a>
            <footer className="flex items-center gap-4 text-sm">
              <button className="inline-flex items-center gap-1"><Icon name="like"/>{it.likes_count||0}</button>
              <a className="inline-flex items-center gap-1" href={`/catch/${it.id}`}><Icon name="comment"/>{it.comments_count||0}</a>
              <button className="inline-flex items-center gap-1" onClick={()=>{
                if (navigator.share) navigator.share({ title:"Улов", url: `/catch/${it.id}` }).catch(()=>{});
              }}><Icon name="share"/>Поделиться</button>
            </footer>
          </article>
        ))}
      </div>

      <div ref={sentinel} className="h-12 flex items-center justify-center text-gray-400">
        {done ? "Это всё на сегодня" : (loading ? "Загрузка..." : "")}
      </div>
    </div>
  );
}
TSX

########################################
# 8) MapScreen: попап с картинками и переходом
########################################
cat > "$SRC/screens/MapScreen.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";
import api from "../data/api";

// Предполагается, что leaflet уже подключён в проекте
// Если используете react-leaflet — адаптируйте импорты.
declare const L:any;

type Point = {
  id:number; title:string; lat:number; lng:number;
  category?:string; photo_url?:string; media_url?:string;
  type?:string;
};

export default function MapScreen(){
  const [points,setPoints]=useState<Point[]>([]);
  const [map,setMap]=useState<any>(null);

  useEffect(()=> {
    if (typeof window !== "undefined" && (window as any).L && !map) {
      const m = L.map('map', { zoomControl: true }).setView([55.75, 37.61], 10);
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; OpenStreetMap'
      }).addTo(m);
      setMap(m);
    }
  },[map]);

  useEffect(()=> {
    (async ()=>{
      try{
        const j:any = await api.points(`?limit=500`);
        const items:Point[] = j?.items || [];
        setPoints(items);
      }catch(e){}
    })();
  },[]);

  useEffect(()=> {
    if(!map) return;
    const layer = L.layerGroup().addTo(map);
    points.forEach(p=>{
      const marker = L.marker([p.lat, p.lng]).addTo(layer);
      const img = p.photo_url || p.media_url;
      const content = `
        <div style="min-width:200px">
          <div style="font-weight:600;margin-bottom:6px">${p.title||"Точка"}</div>
          ${img ? `<img src="${img}" style="width:100%;border-radius:10px;cursor:pointer" id="pin-img-${p.id}"/>` : ""}
          <div style="margin-top:6px">
            <a href="/place/${p.id}" style="color:#2563eb;text-decoration:none">Открыть место</a>
          </div>
        </div>`;
      marker.bindPopup(content);

      marker.on('popupopen', ()=>{
        const el = document.getElementById(`pin-img-${p.id}`);
        if(el){
          el.addEventListener('click', ()=> {
            window.location.href = `/place/${p.id}`;
          }, { once:true });
        }
      });
    });
    return ()=> { map.removeLayer(layer); };
  },[map, points]);

  return (
    <div className="w-full h-full relative">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center justify-between">
        <div className="font-semibold inline-flex items-center gap-2"><Icon name="map"/> Карта</div>
        <a href="/weather" className="text-sm inline-flex items-center gap-1"><Icon name="weather"/> Погода</a>
      </div>
      <div id="map" className="absolute inset-0 z-map" />
    </div>
  );
}
TSX

########################################
# 9) Доработка форм: AddCatch + AddPlace
########################################
cat > "$SRC/screens/AddCatchPage.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";
import api from "../data/api";

export default function AddCatchPage(){
  const [lat,setLat]=useState<number>(55.75);
  const [lng,setLng]=useState<number>(37.61);
  const [species,setSpecies]=useState("");
  const [length,setLength]=useState<number|''>('');
  const [weight,setWeight]=useState<number|''>('');
  const [style,setStyle]=useState("");
  const [lure,setLure]=useState("");
  const [tackle,setTackle]=useState("");
  const [privacy,setPrivacy]=useState<"all"|"friends"|"private">("all");
  const [caughtAt,setCaughtAt]=useState<string>(""); // yyyy-MM-ddTHH:mm
  const [files,setFiles]=useState<FileList|null>(null);
  const [mediaUrl,setMediaUrl]=useState<string>("");

  // погода подставляется, но не блокирует
  const [weather,setWeather]=useState<any>(null);
  useEffect(()=> {
    const dt = caughtAt ? Math.floor(new Date(caughtAt).getTime()/1000) : undefined;
    api.weather(lat,lng,dt).then(setWeather).catch(()=>{});
  },[lat,lng,caughtAt]);

  async function onSubmit(e:React.FormEvent){
    e.preventDefault();
    try{
      let uploaded:string|undefined;
      if(files && files.length){
        const form = new FormData();
        Array.from(files).forEach(f=> form.append("files[]", f));
        const r:any = await api.upload(form);
        uploaded = r?.items?.[0]?.url || r?.url;
      }
      const payload:any = {
        lat, lng,
        species, length: length||null, weight: weight||null,
        style, lure, tackle, privacy,
        caught_at: caughtAt ? new Date(caughtAt).toISOString().slice(0,19).replace('T',' ') : null,
        photo_url: uploaded || mediaUrl || null,
        // погоду кладём как есть (бэкенд может игнорить)
        weather: weather || null,
      };
      const saved:any = await api.addCatch(payload);
      window.location.href = `/catch/${saved?.id || ''}`;
    }catch(err){
      alert("Ошибка сохранения улова");
    }
  }

  return (
    <form onSubmit={onSubmit} className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="photo"/><div className="font-semibold">Добавить улов</div>
      </div>
      <div className="p-4 space-y-3">
        <div>
          <label className="block text-sm mb-1">Координаты</label>
          <div className="flex gap-2">
            <input className="input" placeholder="Широта" value={lat} onChange={e=>setLat(parseFloat(e.target.value)||0)}/>
            <input className="input" placeholder="Долгота" value={lng} onChange={e=>setLng(parseFloat(e.target.value)||0)}/>
          </div>
          <div className="text-xs text-gray-500 mt-1">Можно выбрать точку на карте (будет добавлено в следующем коммите)</div>
        </div>

        <div className="grid grid-cols-2 gap-2">
          <div><label className="block text-sm mb-1">Вид рыбы</label><input className="input" value={species} onChange={e=>setSpecies(e.target.value)} /></div>
          <div><label className="block text-sm mb-1">Стиль</label><input className="input" value={style} onChange={e=>setStyle(e.target.value)} /></div>
          <div><label className="block text-sm mb-1">Приманка</label><input className="input" value={lure} onChange={e=>setLure(e.target.value)} /></div>
          <div><label className="block text-sm mb-1">Снасть</label><input className="input" value={tackle} onChange={e=>setTackle(e.target.value)} /></div>
          <div><label className="block text-sm mb-1">Длина (см)</label><input className="input" type="number" value={length} onChange={e=>setLength(e.target.value===""? "" : Number(e.target.value))} /></div>
          <div><label className="block text-sm mb-1">Вес (г)</label><input className="input" type="number" value={weight} onChange={e=>setWeight(e.target.value===""? "" : Number(e.target.value))} /></div>
        </div>

        <div>
          <label className="block text-sm mb-1">Время поимки</label>
          <input className="input" type="datetime-local" value={caughtAt} onChange={e=>setCaughtAt(e.target.value)} />
        </div>

        <div>
          <label className="block text-sm mb-1">Фото/Видео</label>
          <input type="file" multiple accept="image/*,video/*" onChange={e=>setFiles(e.target.files)} />
          <div className="text-xs text-gray-500 mt-1">Или URL:</div>
          <input className="input" placeholder="https://..." value={mediaUrl} onChange={e=>setMediaUrl(e.target.value)} />
        </div>

        <div>
          <label className="block text-sm mb-1">Доступность</label>
          <select className="input" value={privacy} onChange={e=>setPrivacy(e.target.value as any)}>
            <option value="all">Публично</option>
            <option value="friends">Для друзей</option>
            <option value="private">Приватно</option>
          </select>
        </div>

        <button className="px-4 py-2 rounded-xl bg-black text-white">Сохранить</button>
      </div>
    </form>
  );
}
TSX

cat > "$SRC/screens/AddPlacePage.tsx" <<'TSX'
import React, { useState } from "react";
import Icon from "../components/Icon";
import api from "../data/api";

export default function AddPlacePage(){
  const [lat,setLat]=useState<number>(55.75);
  const [lng,setLng]=useState<number>(37.61);
  const [title,setTitle]=useState("");
  const [category,setCategory]=useState("spot");
  const [files,setFiles]=useState<FileList|null>(null);
  const [mediaUrl,setMediaUrl]=useState("");

  async function onSubmit(e:React.FormEvent){
    e.preventDefault();
    try{
      let uploaded:string|undefined;
      if(files && files.length){
        const form = new FormData();
        Array.from(files).forEach(f=> form.append("files[]", f));
        const r:any = await api.upload(form);
        uploaded = r?.items?.[0]?.url || r?.url;
      }
      const payload = {
        title, lat, lng, category,
        photo_url: uploaded || mediaUrl || null,
      };
      const saved:any = await api.addPlace(payload);
      window.location.href = `/place/${saved?.id || ''}`;
    }catch{
      alert("Ошибка сохранения места");
    }
  }

  return (
    <form onSubmit={onSubmit} className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="place"/><div className="font-semibold">Добавить место</div>
      </div>
      <div className="p-4 space-y-3">
        <div>
          <label className="block text-sm mb-1">Название</label>
          <input className="input" value={title} onChange={e=>setTitle(e.target.value)} />
        </div>
        <div className="grid grid-cols-2 gap-2">
          <div><label className="block text-sm mb-1">Широта</label><input className="input" value={lat} onChange={e=>setLat(parseFloat(e.target.value)||0)} /></div>
          <div><label className="block text-sm mb-1">Долгота</label><input className="input" value={lng} onChange={e=>setLng(parseFloat(e.target.value)||0)} /></div>
        </div>
        <div>
          <label className="block text-sm mb-1">Категория</label>
          <select className="input" value={category} onChange={e=>setCategory(e.target.value)}>
            <option value="spot">Спот</option>
            <option value="shop">Магазин</option>
            <option value="slip">Слип</option>
            <option value="camp">Кемпинг</option>
          </select>
        </div>
        <div>
          <label className="block text-sm mb-1">Фото/Видео</label>
          <input type="file" multiple accept="image/*,video/*" onChange={e=>setFiles(e.target.files)} />
          <div className="text-xs text-gray-500 mt-1">Или URL:</div>
          <input className="input" placeholder="https://..." value={mediaUrl} onChange={e=>setMediaUrl(e.target.value)} />
        </div>
        <button className="px-4 py-2 rounded-xl bg-black text-white">Сохранить</button>
      </div>
    </form>
  );
}
TSX

########################################
# 10) Детальные страницы точки/улова
########################################
cat > "$SRC/screens/PlaceDetailPage.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import api from "../data/api";
import Icon from "../components/Icon";

export default function PlaceDetailPage(){
  const { id } = useParams();
  const [data,setData]=useState<any>(null);

  useEffect(()=>{ if(id) api.placeById(id).then(setData).catch(()=>{}); },[id]);

  if(!data) return <div className="p-4 text-gray-500">Загрузка…</div>;

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <a href="/map" className="mr-1"><Icon name="back"/></a>
        <div className="font-semibold">Место</div>
      </div>
      <div className="p-4 space-y-3">
        <div className="text-xl font-semibold">{data.title||"Точка"}</div>
        {data.photo_url && <img src={data.photo_url} className="w-full rounded-2xl border border-white/50"/>}
        <div className="text-sm text-gray-600">Категория: {data.category||data.type||"—"}</div>
        <div className="text-sm text-gray-600">Координаты: {data.lat}, {data.lng}</div>
        <a href={`/feed?place=${data.id}`} className="inline-flex items-center gap-2 px-3 py-2 rounded-xl bg-black text-white">
          <Icon name="feed"/> Уловы этого места
        </a>
      </div>
    </div>
  );
}
TSX

cat > "$SRC/screens/CatchDetailPage.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import api from "../data/api";
import Icon from "../components/Icon";

export default function CatchDetailPage(){
  const { id } = useParams();
  const [data,setData]=useState<any>(null);
  const [comment,setComment]=useState("");

  useEffect(()=>{ if(id) api.catchById(id).then(setData).catch(()=>{}); },[id]);

  async function sendComment(){
    if(!id || !comment.trim()) return;
    try{ await api.addComment(id, comment.trim()); setComment(""); const j=await api.catchById(id); setData(j); }catch{}
  }
  async function like(){
    if(!id) return; try{ await api.toggleLike(id); const j=await api.catchById(id); setData(j);}catch{}
  }

  if(!data) return <div className="p-4 text-gray-500">Загрузка…</div>;

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <a href="/feed" className="mr-1"><Icon name="back"/></a>
        <div className="font-semibold">Улов</div>
      </div>

      <article className="p-3 space-y-3">
        <header className="flex items-center gap-2">
          <img src={data.user_avatar||"/assets/default-avatar.png"} className="w-8 h-8 rounded-full object-cover"/>
          <a href={`/u/${data.user_id}`} className="font-medium hover:underline">{data.user_name}</a>
          <span className="text-xs text-gray-500 ml-auto">{new Date(data.created_at).toLocaleString()}</span>
        </header>

        <div className="rounded-2xl overflow-hidden bg-white/70 border border-white/50">
          {data.media_url ? <img src={data.media_url} className="w-full object-cover max-h-[70vh]" /> : (
            <div className="w-full aspect-video flex items-center justify-center text-gray-400"><Icon name="photo"/></div>
          )}
        </div>

        <div className="text-sm">
          <div><b>Вид:</b> {data.species||"—"}</div>
          <div><b>Длина:</b> {data.length||"—"} см</div>
          <div><b>Вес:</b> {data.weight||"—"} г</div>
          {!!data.place_id && (
            <div className="mt-2">
              <a className="inline-flex items-center gap-1 text-blue-600 hover:underline" href={`/place/${data.place_id}`}><Icon name="pin"/> Место поимки</a>
            </div>
          )}
        </div>

        <footer className="flex items-center gap-4 text-sm">
          <button className="inline-flex items-center gap-1" onClick={like}><Icon name="like"/>{data.likes_count||0}</button>
          <span className="inline-flex items-center gap-1"><Icon name="comment"/>{data.comments_count||0}</span>
          <button className="inline-flex items-center gap-1" onClick={()=>{
            if (navigator.share) navigator.share({ title:"Улов", url: window.location.href }).catch(()=>{});
          }}><Icon name="share"/>Поделиться</button>
        </footer>

        <section className="mt-3">
          <div className="font-semibold mb-2">Комментарии</div>
          <div className="space-y-2">
            {(data.comments||[]).map((c:any)=>(
              <div key={c.id} className="p-2 rounded-xl bg-white/70 border border-white/50">
                <div className="text-sm"><b>{c.user_name||"Гость"}:</b> {c.body}</div>
                <div className="text-xs text-gray-500 mt-1">{new Date(c.created_at).toLocaleString()}</div>
              </div>
            ))}
          </div>
          <div className="mt-2 flex gap-2">
            <input className="input flex-1" placeholder="Ваш комментарий…" value={comment} onChange={e=>setComment(e.target.value)} />
            <button className="px-3 rounded-xl bg-black text-white" onClick={sendComment}><Icon name="send"/>Отпр</button>
          </div>
        </section>
      </article>
    </div>
  );
}
TSX

########################################
# 11) Погода — ссылка уже была в шапках; убедимся, что страница есть
########################################
cat > "$SRC/screens/WeatherPage.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";
import api from "../data/api";

type Slot={ name:string; lat:number; lng:number; };

export default function WeatherPage(){
  const [slots,setSlots]=useState<Slot[]>(()=> {
    const s = localStorage.getItem("weather_slots");
    return s ? JSON.parse(s) : [{name:"Москва",lat:55.7558,lng:37.6173}];
  });
  const [data,setData]=useState<any[]>([]);

  useEffect(()=> {
    Promise.all(slots.map(async s=>{
      try{ const w = await api.weather(s.lat,s.lng); return { ...s, w }; }catch{ return { ...s, w:null }; }
    })).then(setData);
  },[slots]);

  function addSlot(){
    const name = prompt("Название локации");
    const lat = Number(prompt("Широта")||"");
    const lng = Number(prompt("Долгота")||"");
    if(!name || Number.isNaN(lat) || Number.isNaN(lng)) return;
    const next=[...slots,{name,lat,lng}];
    setSlots(next); localStorage.setItem("weather_slots", JSON.stringify(next));
  }

  function del(i:number){
    const next=slots.slice(); next.splice(i,1); setSlots(next); localStorage.setItem("weather_slots", JSON.stringify(next));
  }

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center justify-between">
        <div className="flex items-center gap-2"><Icon name="weather"/><div className="font-semibold">Погода</div></div>
        <button onClick={addSlot} className="text-sm inline-flex items-center gap-1"><Icon name="plus"/>Локация</button>
      </div>
      <div className="p-3 grid gap-3">
        {data.map((s,i)=>(
          <div key={i} className="p-3 rounded-2xl bg-white/70 border border-white/50">
            <div className="flex items-center justify-between">
              <div className="font-semibold">{s.name}</div>
              <button onClick={()=>del(i)} className="text-xs text-gray-500">убрать</button>
            </div>
            <div className="text-sm text-gray-600">({s.lat}, {s.lng})</div>
            {s.w ? (
              <div className="mt-2 text-lg">
                Темп: {s.w?.temp ?? "—"}°C · Ветер: {s.w?.wind ?? "—"} м/с · Давление: {s.w?.pressure ?? "—"} гПа
              </div>
            ) : <div className="mt-2 text-gray-400">Нет данных</div>}
          </div>
        ))}
      </div>
    </div>
  );
}
TSX

echo "✓ Готово.

ТО, ЧТО НУЖНО СДЕЛАТЬ ПОСЛЕ:
1) Установить роутер:   npm i react-router-dom
2) Проверить, что index.html проксируется Nginx как SPA:
   location / { try_files \$uri /index.html; }

3) Пересобрать фронт:   npm run build

Добавлены/обновлены:
- BrowserRouter (чистые ссылки), маршруты и страницы:
  /map, /feed, /alerts, /profile, /friends, /ratings, /settings,
  /my-catches, /add-catch, /add-place, /catch/:id, /place/:id, /weather
- Нижнее меню вернули (NavLink), FAB по центру
- Карта: попап с картинкой и переходом на /place/:id
- Лента: иконки like/comment/share заменены на Material Symbols
- Формы AddCatch, AddPlace: мультизагрузка, ввод координат, авто-погода (не блокирующая)
"