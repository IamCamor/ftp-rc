#!/usr/bin/env bash
set -euo pipefail

echo "→ Обновление фронта (карта/лента/профиль/авторизация)…"
ROOT="$(pwd)"
SRC="$ROOT/src"; COMP="$SRC/components"; DATA="$SRC/data"; SCREENS="$SRC/screens"; UTILS="$SRC/utils"

[ -f "$ROOT/package.json" ] || { echo "✗ Нет package.json (запусти в корне фронта)"; exit 1; }
mkdir -p "$COMP" "$DATA" "$SCREENS" "$UTILS"

########################################
# package.json (фикс версий, скрипты)
########################################
node - <<'NODE'
const fs=require('fs');
const p=JSON.parse(fs.readFileSync('package.json','utf8'));
p.type = p.type || "module";
p.scripts = {...(p.scripts||{}), dev:"vite", build:"vite build", preview:"vite preview --host", typecheck:"tsc --noEmit"};
p.dependencies = {...(p.dependencies||{}),
  "react":"18.3.1","react-dom":"18.3.1",
  "leaflet":"^1.9.4","react-leaflet":"^4.2.1","lucide-react":"^0.451.0"
};
p.devDependencies = {...(p.devDependencies||{}),
  "vite":"^5.4.6","@vitejs/plugin-react-swc":"^3.5.0","typescript":"^5.5.4",
  "tailwindcss":"^3.4.10","postcss":"^8.4.39","autoprefixer":"^10.4.19"
};
fs.writeFileSync('package.json', JSON.stringify(p,null,2));
console.log("✓ package.json обновлён");
NODE

########################################
# vite.config.ts (SPA)
########################################
cat > "$ROOT/vite.config.ts" <<'TS'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
export default defineConfig({
  plugins:[react()],
  build:{ outDir:"dist", assetsDir:"assets", sourcemap:false, chunkSizeWarningLimit:1000 },
  server:{ host:true, port:5173 },
  preview:{ host:true, port:4173 }
});
TS

########################################
# tsconfig + vite-env
########################################
cat > "$ROOT/tsconfig.json" <<'JSON'
{
  "compilerOptions": {
    "target": "ES2020", "lib": ["ES2020","DOM","DOM.Iterable"],
    "module": "ESNext", "moduleResolution": "Bundler", "resolveJsonModule": true,
    "jsx": "react-jsx", "noEmit": true, "skipLibCheck": true,
    "isolatedModules": true, "strict": true, "allowJs": false
  },
  "include": ["src"]
}
JSON

mkdir -p "$SRC"
cat > "$SRC/vite-env.d.ts" <<'DTS'
/// <reference types="vite/client" />
DTS

########################################
# Tailwind/PostCSS
########################################
cat > "$ROOT/tailwind.config.js" <<'JS'
export default { content: ["./index.html","./src/**/*.{ts,tsx}"], theme:{ extend:{} }, plugins:[] }
JS
cat > "$ROOT/postcss.config.js" <<'JS'
export default { plugins: { tailwindcss: {}, autoprefixer: {} } }
JS

########################################
# index.html (если нет)
########################################
if [ ! -f "$ROOT/index.html" ]; then
cat > "$ROOT/index.html" <<'HTML'
<!doctype html>
<html lang="ru">
  <head>
    <meta charset="UTF-8" /><meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>FishTrackPro</title>
  </head>
  <body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body>
</html>
HTML
fi

########################################
# index.css (Leaflet импорт первым + стили)
########################################
cat > "$SRC/index.css" <<'CSS'
@import "leaflet/dist/leaflet.css";
@tailwind base;
@tailwind components;
@tailwind utilities;

.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }

.glass { backdrop-filter: blur(20px); background: rgba(255,255,255,.20); border: 1px solid rgba(255,255,255,.3); box-shadow: 0 6px 24px rgba(0,0,0,.08); }
.glass-soft { backdrop-filter: blur(20px); background: rgba(255,255,255,.15); border-top: 1px solid rgba(255,255,255,.25); }
.grad-ig { background-image: linear-gradient(135deg,#FF7CA3 0%,#FFB88C 100%); }

.leaflet-pane.leaflet-tile-pane { z-index: 100 !important; }
.leaflet-pane.leaflet-overlay-pane { z-index: 300 !important; }
.leaflet-pane.leaflet-marker-pane { z-index: 400 !important; }
.leaflet-pane.leaflet-popup-pane { z-index: 800 !important; }
.leaflet-control-container { z-index: 900 !important; }
CSS

########################################
# ENV (пример/прод)
########################################
[ -f "$ROOT/.env.example" ] || cat > "$ROOT/.env.example" <<'ENV'
VITE_API_BASE=https://api.fishtrackpro.ru
ENV
[ -f "$ROOT/.env.production" ] || cp "$ROOT/.env.example" "$ROOT/.env.production"

########################################
# utils
########################################
cat > "$UTILS/useDebounce.ts" <<'TS'
import { useEffect, useState } from "react";
export function useDebounce<T>(value:T, ms=400){ const [v,setV]=useState(value);
  useEffect(()=>{const t=setTimeout(()=>setV(value),ms); return()=>clearTimeout(t);},[value,ms]); return v; }
TS

########################################
# data: types, auth, api
########################################
cat > "$DATA/types.ts" <<'TS'
export type PointType="spot"|"shop"|"slip"|"camp"|"catch"|string;
export type Point={ id:number; title:string; lat:number; lng:number; type?:PointType; description?:string|null; address?:string|null; tags?:string[]|null; };
TS

cat > "$DATA/auth.ts" <<'TS'
import { useEffect, useState } from "react";
const TOKEN_KEY="ftp_token";
export const getToken=()=>localStorage.getItem(TOKEN_KEY);
export const setToken=(t:string|null)=>t?localStorage.setItem(TOKEN_KEY,t):localStorage.removeItem(TOKEN_KEY);
export const authHeader=()=>{const t=getToken(); return t?{Authorization:`Bearer ${t}`}:{}}; 
export function useAuthState(){ const [isAuthed,setAuthed]=useState(!!getToken());
  useEffect(()=>{const on=()=>setAuthed(!!getToken()); window.addEventListener("storage",on); return()=>window.removeEventListener("storage",on);},[]);
  return {isAuthed,setAuthed}; }
TS

cat > "$DATA/api.ts" <<'TS'
import type { Point, PointType } from "./types";
import { authHeader } from "./auth";

const API_BASE = (import.meta as any).env?.VITE_API_BASE?.toString().trim() || "";

export type GetPointsParams={ filter?:PointType; bbox?:[number,number,number,number]; limit?:number; q?:string; };
export async function getPoints(params:GetPointsParams={}):Promise<Point[]>{
  if(!API_BASE) throw new Error("VITE_API_BASE is not set");
  const u=new URL(`${API_BASE}/api/v1/map/points`);
  u.searchParams.set("limit", String(params.limit ?? 500));
  if(params.filter) u.searchParams.set("filter", params.filter);
  if(params.bbox) u.searchParams.set("bbox", params.bbox.join(","));
  if(params.q) u.searchParams.set("q", params.q);
  const res=await fetch(u.toString(),{headers:{Accept:"application/json"}});
  const ct=res.headers.get("content-type")||"";
  if(!res.ok || !ct.includes("application/json")) throw new Error(`Bad API response: ${res.status}`);
  const data=await res.json(); const items:any[]=data?.items ?? data ?? [];
  return items.map((it:any,i:number)=>({
    id:Number(it.id ?? i+1),
    title:String(it.title ?? `Point ${i+1}`),
    lat:Number(it.lat ?? it.latitude), lng:Number(it.lng ?? it.longitude),
    type: it.type ?? it.category ?? undefined,
    description: it.description ?? it.note ?? null,
    address: it.address ?? null,
    tags: Array.isArray(it.tags)?it.tags: (typeof it.tags==="string"? it.tags.split(",").map((s:string)=>s.trim()).filter(Boolean): null)
  }));
}

// AUTH
export async function login(body:{email:string;password:string;}):Promise<{token:string}>{
  const res=await fetch(`${API_BASE}/api/v1/login`,{method:"POST",headers:{"Content-Type":"application/json",Accept:"application/json"},body:JSON.stringify(body)});
  if(!res.ok) throw new Error("Неверный email или пароль"); return res.json();
}
export async function registerUser(body:{email:string;password:string;name:string;}):Promise<{token:string}>{
  const res=await fetch(`${API_BASE}/api/v1/register`,{method:"POST",headers:{"Content-Type":"application/json",Accept:"application/json"},body:JSON.stringify(body)});
  if(!res.ok) throw new Error("Не удалось зарегистрироваться"); return res.json();
}
export async function getMe(){
  const res=await fetch(`${API_BASE}/api/v1/me`,{headers:{Accept:"application/json",...authHeader()}});
  if(!res.ok) throw new Error("Не авторизованы"); return res.json();
}
export async function logout(){ await fetch(`${API_BASE}/api/v1/logout`,{method:"POST",headers:{...authHeader()}}); }

// FEED
export async function fetchFeed(params:{q?:string;limit?:number}={}){
  const u=new URL(`${API_BASE}/api/v1/feed`); if(params.q) u.searchParams.set("q",params.q); if(params.limit) u.searchParams.set("limit",String(params.limit));
  const res=await fetch(u.toString(),{headers:{Accept:"application/json",...authHeader()}});
  if(!res.ok) throw new Error("Ошибка загрузки ленты"); return res.json();
}
export async function likePost(id:number){
  const res=await fetch(`${API_BASE}/api/v1/feed/${id}/like`,{method:"POST",headers:{Accept:"application/json",...authHeader()}});
  if(!res.ok) throw new Error("Не удалось поставить лайк"); return res.json();
}
TS

########################################
# components: SearchBar, FilterChips, BottomNav, MapView, FeedCard
########################################
cat > "$COMP/SearchBar.tsx" <<'TSX'
import React from "react";
export default function SearchBar({ value, onChange }: {value:string; onChange:(v:string)=>void}) {
  return (
    <div className="fixed top-4 left-1/2 -translate-x-1/2 w-[92%] z-[1200]">
      <div className="glass rounded-2xl px-4 py-2 flex items-center">
        <span className="mr-2">🔍</span>
        <input value={value} onChange={(e)=>onChange(e.target.value)} placeholder="Поиск…"
               className="bg-transparent outline-none text-sm w-full text-gray-800 placeholder:text-gray-500"/>
      </div>
    </div>
  );
}
TSX

cat > "$COMP/FilterChips.tsx" <<'TSX'
import React from "react";
export const FILTERS = ["Все","Споты","Магазины","Слипы","Кемпинги","Уловы"] as const;
export type FilterName = typeof FILTERS[number];
export default function FilterChips({active,onChange}:{active:FilterName; onChange:(f:FilterName)=>void}) {
  return (
    <div className="fixed top-16 left-0 w-full px-3 z-[1190]">
      <div className="flex gap-3 overflow-x-auto pb-2 no-scrollbar">
        {FILTERS.map((f)=> {
          const is = active===f;
          return (
            <button key={f} onClick={()=>onChange(f)}
              className={"px-4 py-2 rounded-xl text-sm whitespace-nowrap "+(is? "text-white shadow grad-ig":"glass text-gray-700")}>
              {f}
            </button>
          );
        })}
      </div>
    </div>
  );
}
TSX

cat > "$COMP/BottomNav.tsx" <<'TSX'
import React from "react";
import { Home, MapPin, Bell, User, Plus } from "lucide-react";
type Tab="feed"|"map"|"alerts"|"profile";
export default function BottomNav({onFab,active,onChange}:{onFab:()=>void; active:Tab; onChange:(t:Tab)=>void}) {
  const cn=(t:Tab)=>"flex flex-col items-center "+(active===t?"text-black":"text-gray-600");
  return (
    <div className="fixed bottom-0 left-0 w-full h-16 glass-soft flex items-center justify-around z-[1200]">
      <button className={cn("feed")} onClick={()=>onChange("feed")} aria-label="Лента"><Home size={22}/><span className="text-[11px]">Лента</span></button>
      <button className={cn("map")} onClick={()=>onChange("map")} aria-label="Карта"><MapPin size={22}/><span className="text-[11px]">Карта</span></button>
      <button onClick={onFab} aria-label="Добавить" className="absolute -top-6 left-1/2 -translate-x-1/2 rounded-full p-4 shadow-lg grad-ig text-white"><Plus size={26}/></button>
      <button className={cn("alerts")} onClick={()=>onChange("alerts")} aria-label="Уведомления"><Bell size={22}/><span className="text-[11px]">Уведомл.</span></button>
      <button className={cn("profile")} onClick={()=>onChange("profile")} aria-label="Профиль"><User size={22}/><span className="text-[11px]">Профиль</span></button>
    </div>
  );
}
TSX

cat > "$COMP/MapView.tsx" <<'TSX'
import React, { useEffect, useMemo, useRef, useState } from "react";
import { MapContainer, TileLayer, CircleMarker, Popup, useMapEvents } from "react-leaflet";
import type { LatLngBounds, LatLngExpression } from "leaflet";
import { getPoints } from "../data/api";
import type { Point } from "../data/types";
import { useDebounce } from "../utils/useDebounce";

export default function MapView({ filter, q }:{filter:"Все"|"Споты"|"Магазины"|"Слипы"|"Кемпинги"|"Уловы"; q:string}) {
  const [points,setPoints]=useState<Point[]>([]); const [error,setError]=useState<string|null>(null);
  const [bounds,setBounds]=useState<LatLngBounds|null>(null); const debouncedQ=useDebounce(q,300); const loading=useRef(false);
  const center:LatLngExpression=[55.7558,37.6173];
  const mapFilter:Record<string,string|undefined>={ "Все":undefined,"Споты":"spot","Магазины":"shop","Слипы":"slip","Кемпинги":"camp","Уловы":"catch" };

  function BoundsWatcher({on}:{on:(b:LatLngBounds)=>void}){ useMapEvents({moveend:(e)=>on(e.target.getBounds()), zoomend:(e)=>on(e.target.getBounds())}); return null; }

  useEffect(()=>{ let cancel=false;
    (async()=>{
      if(loading.current) return; loading.current=true; setError(null);
      try{
        const t=mapFilter[filter]; const bbox=bounds?[bounds.getWest(),bounds.getSouth(),bounds.getEast(),bounds.getNorth()] as [number,number,number,number]:undefined;
        const items=await getPoints({filter:t,bbox,limit:500,q:debouncedQ}); if(!cancel) setPoints(items);
      }catch(e:any){ if(!cancel) setError(e?.message??"Ошибка загрузки"); } finally{ loading.current=false; }
    })(); return ()=>{cancel=true};
  },[filter,bounds,debouncedQ]);

  const shown=useMemo(()=>{ const text=debouncedQ.trim().toLowerCase(); if(!text) return points;
    return points.filter(p=>[p.title,p.description??"",p.address??"",...(p.tags??[])].join(" ").toLowerCase().includes(text));
  },[points,debouncedQ]);

  return (
    <div className="w-full h-full">
      <MapContainer center={center} zoom={12} className="w-full h-full">
        <TileLayer url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png" attribution='&copy; <a href="https://carto.com/">CARTO</a>'/>
        <BoundsWatcher on={setBounds}/>
        {shown.map(p=>(
          <CircleMarker key={p.id} center={[p.lat,p.lng]} radius={8} pathOptions={{color:"#FF7CA3",weight:2,fillColor:"#FFB88C",fillOpacity:0.9}}>
            <Popup>
              <div className="text-sm max-w-[220px]">
                <div className="font-medium">{p.title}</div>
                {p.type && <div className="text-gray-500 mt-1">Тип: {p.type}</div>}
                {p.description && <div className="mt-1">{p.description}</div>}
                {p.address && <div className="mt-1 text-gray-600">{p.address}</div>}
                {p.tags?.length ? <div className="mt-1 text-xs text-gray-500">#{p.tags.join(" #")}</div> : null}
              </div>
            </Popup>
          </CircleMarker>
        ))}
      </MapContainer>
      {error && <div className="fixed top-24 left-1/2 -translate-x-1/2 px-3 py-1 text-xs rounded-md text-white bg-red-500/80 z-[1400]">{error}</div>}
    </div>
  );
}
TSX

cat > "$COMP/FeedCard.tsx" <<'TSX'
import React from "react";
export type FeedItem={ id:number; author:{id:number;name:string;avatar?:string|null}; title?:string|null; text?:string|null; photo?:string|null; created_at?:string|null; likes?:number; comments?:number; };
export default function FeedCard({item,onLike,onOpen}:{item:FeedItem; onLike?:(id:number)=>void; onOpen?:(id:number)=>void;}){
  return (
    <div className="glass rounded-2xl p-3 mb-3">
      <div className="flex items-center gap-2 mb-2">
        <img src={item.author.avatar||"https://www.gravatar.com/avatar?d=mp"} alt="" className="w-8 h-8 rounded-full object-cover"/>
        <div className="flex-1">
          <div className="text-sm font-medium">{item.author.name}</div>
          {item.created_at && <div className="text-[11px] text-gray-500">{new Date(item.created_at).toLocaleString()}</div>}
        </div>
      </div>
      {item.title && <div className="font-medium mb-1">{item.title}</div>}
      {item.text && <div className="text-sm text-gray-700 mb-2">{item.text}</div>}
      {item.photo && <div className="overflow-hidden rounded-xl mb-2"><img src={item.photo} className="w-full h-auto" alt="" onClick={()=>onOpen?.(item.id)}/></div>}
      <div className="flex items-center gap-4 text-sm text-gray-700">
        <button onClick={()=>onLike?.(item.id)} className="flex items-center gap-1">❤️ <span>{item.likes??0}</span></button>
        <button className="flex items-center gap-1" onClick={()=>onOpen?.(item.id)}>💬 <span>{item.comments??0}</span></button>
      </div>
    </div>
  );
}
TSX

########################################
# screens: Map, Feed, Profile, Auth
########################################
cat > "$SCREENS/MapScreen.tsx" <<'TSX'
import React, { useState } from "react";
import SearchBar from "../components/SearchBar";
import FilterChips, { FilterName } from "../components/FilterChips";
import MapView from "../components/MapView";
export default function MapScreen(){
  const [search,setSearch]=useState(""); const [filter,setFilter]=useState<FilterName>("Все");
  return (
    <div className="relative w-full h-full bg-gray-100">
      <SearchBar value={search} onChange={setSearch}/>
      <FilterChips active={filter} onChange={setFilter}/>
      <div className="w-full h-full"><MapView filter={filter} q={search}/></div>
    </div>
  );
}
TSX

cat > "$SCREENS/FeedScreen.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import FeedCard, { FeedItem } from "../components/FeedCard";
import { fetchFeed, likePost } from "../data/api";
import SearchBar from "../components/SearchBar";
import { useDebounce } from "../utils/useDebounce";
export default function FeedScreen(){
  const [items,setItems]=useState<FeedItem[]>([]); const [q,setQ]=useState(""); const [err,setErr]=useState<string|null>(null); const [loading,setLoading]=useState(false);
  const dq=useDebounce(q,300);
  useEffect(()=>{ let c=false; (async()=>{ setLoading(true); setErr(null);
    try{ const data=await fetchFeed({q:dq,limit:50}); if(!c) setItems(data); }catch(e:any){ if(!c) setErr(e?.message||"Ошибка загрузки ленты"); }finally{ setLoading(false); }
  })(); return()=>{c=true}; },[dq]);
  const onLike=async(id:number)=>{ try{ await likePost(id); setItems(p=>p.map(x=>x.id===id?{...x,likes:(x.likes??0)+1}:x)); }catch{} };
  return (
    <div className="w-full h-full overflow-y-auto pb-24 pt-16 px-3">
      <SearchBar value={q} onChange={setQ}/>
      {err && <div className="mt-16 text-sm text-red-600">{err}</div>}
      {!err && loading && <div className="mt-16 text-gray-500">Загрузка…</div>}
      {!loading && !items.length && <div className="mt-16 text-gray-500">Пока пусто</div>}
      <div className="mt-2">{items.map(it=><FeedCard key={it.id} item={it} onLike={onLike} onOpen={(id)=>alert(`Открыть пост #${id}`)}/>)}</div>
    </div>
  );
}
TSX

cat > "$SCREENS/ProfileScreen.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { getMe, logout } from "../data/api";
import { setToken } from "../data/auth";
type Me={ id:number; name:string; email:string; avatar?:string|null; stats?:{catches?:number;points?:number;likes?:number}};
export default function ProfileScreen(){
  const [me,setMe]=useState<Me|null>(null); const [err,setErr]=useState<string|null>(null);
  useEffect(()=>{ let c=false; (async()=>{ try{ const u=await getMe(); if(!c) setMe(u);}catch(e:any){ if(!c) setErr(e?.message||"Ошибка профиля"); }})(); return()=>{c=true}; },[]);
  const onLogout=async()=>{ try{ await logout(); }catch{} setToken(null); location.reload(); };
  if(err) return <div className="w-full h-full flex items-center justify-center text-red-600">{err}</div>;
  if(!me) return <div className="w-full h-full flex items-center justify-center text-gray-500">Загрузка…</div>;
  return (
    <div className="w-full h-full overflow-y-auto pb-24 pt-6 px-4">
      <div className="glass rounded-2xl p-4 flex items-center gap-3">
        <img src={me.avatar||"https://www.gravatar.com/avatar?d=mp"} className="w-16 h-16 rounded-full object-cover" alt=""/>
        <div className="flex-1"><div className="text-lg font-semibold">{me.name}</div><div className="text-sm text-gray-600">{me.email}</div></div>
        <button onClick={onLogout} className="text-sm text-red-600 underline">Выйти</button>
      </div>
      <div className="grid grid-cols-3 gap-3 mt-4">
        <div className="glass rounded-2xl p-3 text-center"><div className="text-xl font-semibold">{me.stats?.catches??0}</div><div className="text-xs text-gray-600">уловы</div></div>
        <div className="glass rounded-2xl p-3 text-center"><div className="text-xl font-semibold">{me.stats?.points??0}</div><div className="text-xs text-gray-600">точки</div></div>
        <div className="glass rounded-2xl p-3 text-center"><div className="text-xl font-semibold">{me.stats?.likes??0}</div><div className="text-xs text-gray-600">лайки</div></div>
      </div>
    </div>
  );
}
TSX

cat > "$SCREENS/AuthScreen.tsx" <<'TSX'
import React, { useState } from "react";
import { login, registerUser } from "../data/api";
import { setToken } from "../data/auth";
export default function AuthScreen({onClose}:{onClose?:()=>void}){
  const [mode,setMode]=useState<"login"|"register">("login");
  const [email,setEmail]=useState(""); const [password,setPassword]=useState(""); const [displayName,setDisplayName]=useState("");
  const [error,setError]=useState<string|null>(null); const [loading,setLoading]=useState(false);
  const submit=async(e:React.FormEvent)=>{ e.preventDefault(); setLoading(true); setError(null);
    try{ const {token} = mode==="login" ? await login({email,password}) : await registerUser({email,password,name:displayName});
      setToken(token); onClose?.(); } catch(err:any){ setError(err?.message||"Ошибка"); } finally{ setLoading(false); }
  };
  return (
    <div className="fixed inset-0 z-[2000] flex items-center justify-center bg-black/30">
      <div className="glass rounded-2xl w-[92%] max-w-md p-5">
        <div className="flex justify-between items-center mb-3">
          <h3 className="text-lg font-semibold">{mode==="login"?"Войти":"Регистрация"}</h3>
          <button onClick={onClose} className="text-gray-500">✕</button>
        </div>
        <form onSubmit={submit} className="space-y-3">
          {mode==="register" && (<div><label className="text-sm text-gray-700">Отображаемое имя</label>
            <input className="w-full bg-white/60 rounded-xl p-2 outline-none" value={displayName} onChange={(e)=>setDisplayName(e.target.value)} required/></div>)}
          <div><label className="text-sm text-gray-700">Email</label>
            <input type="email" className="w-full bg-white/60 rounded-xl p-2 outline-none" value={email} onChange={(e)=>setEmail(e.target.value)} required/></div>
          <div><label className="text-sm text-gray-700">Пароль</label>
            <input type="password" className="w-full bg-white/60 rounded-xl p-2 outline-none" value={password} onChange={(e)=>setPassword(e.target.value)} required/></div>
          {error && <div className="text-sm text-red-600">{error}</div>}
          <button disabled={loading} className="w-full grad-ig text-white rounded-xl py-2 shadow">{loading?"…":(mode==="login"?"Войти":"Зарегистрироваться")}</button>
        </form>
        <div className="text-center mt-3 text-sm">
          {mode==="login"? <>Нет аккаунта? <button className="underline" onClick={()=>setMode("register")}>Создать</button></>
                         : <>Уже с нами? <button className="underline" onClick={()=>setMode("login")}>Войти</button></>}
        </div>
      </div>
    </div>
  );
}
TSX

########################################
# App + main
########################################
cat > "$SRC/App.tsx" <<'TSX'
import React, { useMemo, useState } from "react";
import MapScreen from "./screens/MapScreen";
import FeedScreen from "./screens/FeedScreen";
import ProfileScreen from "./screens/ProfileScreen";
import AuthScreen from "./screens/AuthScreen";
import BottomNav from "./components/BottomNav";
import { useAuthState } from "./data/auth";
type Tab="map"|"feed"|"alerts"|"profile";
export default function App(){
  const [tab,setTab]=useState<Tab>("map"); const {isAuthed}=useAuthState();
  const needAuth=useMemo(()=> (tab==="feed"||tab==="profile") && !isAuthed, [tab,isAuthed]);
  const onFab=()=>{ if(tab==="map") alert("Форма добавления точки"); else if(tab==="feed") alert("Форма публикации"); else alert("Действие появится позже"); };
  return (
    <div className="relative w-full h-screen bg-gray-100">
      {tab==="map" && <MapScreen/>}
      {tab==="feed" && <FeedScreen/>}
      {tab==="alerts" && <div className="w-full h-full flex items-center justify-center text-gray-600">Уведомления скоро будут</div>}
      {tab==="profile" && <ProfileScreen/>}
      <BottomNav onFab={onFab} active={tab} onChange={setTab as any}/>
      {needAuth && <AuthScreen onClose={()=>setTab("map")}/>}
    </div>
  );
}
TSX

cat > "$SRC/main.tsx" <<'TSX'
import React from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App";
createRoot(document.getElementById("root")!).render(<App />);
TSX

echo "✓ Файлы обновлены."
echo "Дальше:"
echo "  1) Проверь .env.local или .env.production: VITE_API_BASE=https://api.fishtrackpro.ru"
echo "  2) npm i"
echo "  3) npm run dev   (локально)   или   npm run build && rsync на сервер (прод)"
