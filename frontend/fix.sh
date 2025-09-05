#!/usr/bin/env bash
set -euo pipefail

# === настройки пути к фронту (если фронтенд в ./frontend, оставь как есть) ===
FRONT="."   # или FRONT="frontend"

mkdir -p "$FRONT/public" "$FRONT/src/components" "$FRONT/src/pages" "$FRONT/src/styles"

# ---------- public/index.html ----------
cat > "$FRONT/public/index.html" <<'EOF'
<!doctype html>
<html lang="ru">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover" />
    <meta name="color-scheme" content="light dark" />
    <title>FishTrack Pro</title>

    <!-- Material Symbols (альфавитный порядок осей!) -->
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:FILL,GRAD,opsz,wght@0,0,24,400" rel="stylesheet" />
    <style>
      .material-symbols-rounded{font-variation-settings:"FILL" 0,"GRAD" 0,"opsz" 24,"wght" 400}
    </style>

    <!-- Leaflet CSS/JS (через CDN) -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
      integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="anonymous"/>
    <script defer src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
      integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin="anonymous"></script>

    <script type="module" src="/src/main.tsx"></script>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
EOF

# ---------- src/styles/app.css ----------
cat > "$FRONT/src/styles/app.css" <<'EOF'
:root{
  --bg: #0b0f17;
  --card: rgba(255,255,255,0.06);
  --stroke: rgba(255,255,255,0.15);
  --text: #eaf2ff;
  --muted: #9fb2cc;
  --accent: #53b1ff;
  --glass: rgba(255,255,255,0.12);
  --blur: 16px;
}

*{box-sizing:border-box}
html,body,#root{height:100%;margin:0;background:linear-gradient(180deg,#0a0e16 0%,#0e1420 100%) fixed;color:var(--text);font-family:system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,Cantarell,Helvetica,Arial,"Apple Color Emoji","Segoe UI Emoji"}
a{color:inherit;text-decoration:none}

.container{max-width:1100px;margin:0 auto;padding:0 16px}

.glass{
  background: var(--glass);
  border: 1px solid var(--stroke);
  backdrop-filter: blur(var(--blur));
  -webkit-backdrop-filter: blur(var(--blur));
  box-shadow: 0 10px 30px rgba(0,0,0,.25), inset 0 1px 0 rgba(255,255,255,.08);
  border-radius: 16px;
}

.glass-card{
  background: var(--card);
  border: 1px solid var(--stroke);
  border-radius: 16px;
  backdrop-filter: blur(12px);
}

.header{
  position:sticky;top:0;z-index:50;
  padding:10px 12px;margin:8px;
}

.header .row{display:flex;align-items:center;gap:10px}
.header .right{margin-left:auto;display:flex;gap:12px;align-items:center}

.tabs{
  position:fixed;bottom:0;left:0;right:0;z-index:40;
  padding:8px;margin:10px;
}

.tabs .inner{
  display:grid;grid-template-columns:repeat(4,1fr);gap:10px;
  padding:10px 12px;align-items:center;
}

.tab{display:flex;gap:8px;justify-content:center;align-items:center;padding:10px 12px;border-radius:12px;color:var(--muted);cursor:pointer}
.tab.active{color:white;background:rgba(255,255,255,0.08);}

.badge{display:inline-flex;align-items:center;gap:6px;padding:6px 10px;border-radius:999px;background:rgba(255,255,255,.08);border:1px solid var(--stroke);color:var(--text);font-size:13px}

.map-wrap{position:relative;height:calc(100dvh - 120px);margin:12px}
#map{height:100%;border-radius:16px;overflow:hidden;border:1px solid var(--stroke)}
.map-overlay{
  position:absolute;left:12px;right:12px;bottom:12px;display:flex;gap:12px;pointer-events:none;
}
.map-overlay .panel{pointer-events:auto;flex:1;min-height:80px;padding:10px}

.fab{
  position:fixed;right:18px;bottom:88px;z-index:48;
}
.fab .btn{
  width:56px;height:56px;border-radius:50%;background:var(--accent);color:#00111f;display:grid;place-items:center;
  box-shadow:0 10px 30px rgba(0,0,0,.35);
  cursor:pointer;border:none;
}
.fab-menu{position:absolute;bottom:64px;right:0;display:flex;flex-direction:column;gap:10px}
.fab-menu .action{display:flex;align-items:center;gap:8px}
.fab-menu .action .chip{padding:6px 10px;border-radius:10px;background:rgba(0,0,0,.5);border:1px solid var(--stroke);font-size:13px}

.card{padding:14px;border-radius:14px;border:1px solid var(--stroke);background:rgba(255,255,255,.04)}
.row{display:flex;gap:10px;align-items:center}
.grid{display:grid;gap:12px}
.grid.cols-2{grid-template-columns:1fr 1fr}

.media-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:6px}
.media-grid img, .media-grid video{width:100%;height:100%;object-fit:cover;border-radius:10px;border:1px solid var(--stroke)}

.icon{font-size:22px;line-height:1;display:inline-flex;vertical-align:middle}
.small{font-size:14px;color:var(--muted)}
.input, .select, .button{
  width:100%;padding:10px 12px;border-radius:12px;border:1px solid var(--stroke);background:rgba(255,255,255,.06);color:var(--text)
}
.button.primary{background:var(--accent);color:#00111f;border:none;cursor:pointer}
.button.ghost{background:transparent;border:1px solid var(--stroke);cursor:pointer}
.form-grid{display:grid;gap:12px}
.form-inline{display:grid;grid-template-columns:1fr 1fr;gap:12px}

.toast{
  position:fixed;left:50%;transform:translateX(-50%);
  bottom:120px;z-index:60;padding:8px 12px;border-radius:12px;background:#111b2a;color:#d8e6ff;border:1px solid var(--stroke)
}
.leaflet-popup-content-wrapper{border-radius:14px}
.leaflet-control-attribution{display:none}
EOF

# ---------- src/config.ts ----------
cat > "$FRONT/src/config.ts" <<'EOF'
export const CONFIG = {
  API_BASE: (import.meta.env.VITE_API_BASE as string) || 'https://api.fishtrackpro.ru/api/v1',
  CDN_BASE: (import.meta.env.VITE_CDN_BASE as string) || '',
  IMAGES: {
    logo: '/logo.svg',
    avatarDefault: '/default-avatar.png',
    bgPattern: '/bg-pattern.png',
  },
  Icons: {
    map: 'map',
    feed: 'dynamic_feed',
    alerts: 'notifications',
    profile: 'account_circle',
    plus: 'add',
    addCatch: 'fish',              // material symbol: "fish"
    addPlace: 'add_location_alt',
    like: 'favorite',
    comment: 'forum',
    share: 'ios_share',
    weather: 'sunny',
    wind: 'air',
    temp: 'device_thermostat',
    location: 'my_location',
    back: 'arrow_back',
    more: 'more_vert',
    bookmark: 'bookmark_add',
  } as const,
};
export type IconName = keyof typeof CONFIG.Icons;
EOF

# ---------- src/types.ts ----------
cat > "$FRONT/src/types.ts" <<'EOF'
export type Id = number | string;

export interface Media {
  url: string;
  type: 'image' | 'video';
}

export interface Point {
  id: Id;
  title: string;
  type: 'shop'|'slip'|'camp'|'catch'|'spot'|string;
  lat: number; lng: number;
  photo?: { url: string } | null;
  photos?: Media[];
}

export interface CatchItem {
  id: Id;
  user_id: Id;
  user_name: string;
  user_avatar?: string;
  species?: string|null;
  length?: number|null;
  weight?: number|null;
  method?: string|null;
  bait?: string|null;
  gear?: string|null;
  caption?: string|null;
  media_url?: string|null;
  created_at: string;
  lat?: number; lng?: number;
  place_id?: Id|null;
  likes_count?: number;
  comments_count?: number;
  liked_by_me?: 0|1;
}

export interface WeatherNow {
  temp_c?: number|null;
  wind_ms?: number|null;
  source?: string;
}

export interface NotificationItem {
  id: Id;
  title: string;
  body?: string;
  created_at: string;
  read?: boolean;
}

export interface ProfileMe {
  id: Id;
  name: string;
  avatar?: string;
  bonuses?: number;
}
EOF

# ---------- src/api.ts ----------
cat > "$FRONT/src/api.ts" <<'EOF'
import { CONFIG } from './config';
import type { CatchItem, Point, WeatherNow, NotificationItem, ProfileMe } from './types';

const BASE = CONFIG.API_BASE;

// Базовый fetch с отключёнными куками для публичных GET (чтобы не упираться в CORS credentials)
async function get(path: string, opts: RequestInit = {}){
  const res = await fetch(`${BASE}${path}`, { method:'GET', credentials:'omit', ...opts });
  if(!res.ok) throw new Error(`${res.status}`);
  return res.json();
}
async function post(path: string, body: any, isForm=false){
  const init: RequestInit = { method:'POST', credentials:'include' };
  if(isForm){
    init.body = body as FormData;
  } else {
    init.headers = { 'Content-Type':'application/json' };
    init.body = JSON.stringify(body);
  }
  const res = await fetch(`${BASE}${path}`, init);
  if(!res.ok) throw new Error(`${res.status}`);
  return res.json();
}

// Карта/точки
export async function points(params: {limit?:number; filter?:string; bbox?:[number,number,number,number]} = {}): Promise<Point[]> {
  const p = new URLSearchParams();
  if(params.limit) p.set('limit', String(params.limit));
  if(params.filter) p.set('filter', params.filter);
  if(params.bbox) p.set('bbox', params.bbox.join(','));
  const data = await get(`/map/points?${p.toString()}`);
  // сервер возвращает {items:[...]}
  const items = Array.isArray(data?.items) ? data.items : [];
  return items as Point[];
}

// Лента
export async function feed(limit=10, offset=0): Promise<CatchItem[]> {
  const p = new URLSearchParams();
  p.set('limit', String(limit));
  p.set('offset', String(offset));
  const data = await get(`/feed?${p.toString()}`);
  return Array.isArray(data?.items) ? data.items : [];
}

// Улов
export async function catchById(id: number|string): Promise<CatchItem> {
  const data = await get(`/catch/${id}`);
  return data as CatchItem;
}
export async function addCatch(payload: any){
  // backend ожидает либо JSON, либо multipart — используем JSON (фото — отдельной загрузкой)
  return post(`/catches`, payload, false);
}

// Точки
export async function addPlace(payload: any){
  return post(`/points`, payload, false);
}

// Погода proxy
export async function weather(lat:number, lng:number, dt?:number): Promise<WeatherNow>{
  const p = new URLSearchParams();
  p.set('lat', String(lat));
  p.set('lng', String(lng));
  if(dt) p.set('dt', String(dt));
  try{
    const data = await get(`/weather?${p.toString()}`);
    return data;
  }catch(e){
    // не блокируем — вернём пустую погоду
    return { temp_c:null, wind_ms:null, source:'none' };
  }
}

// Медиа
export async function upload(files: File[]): Promise<{urls:string[]}>{
  const fd = new FormData();
  files.forEach(f=>fd.append('files[]', f));
  return post(`/upload`, fd, true);
}

// Профиль/уведомления (могут быть за auth; если 401 — вернём заглушки)
export async function profileMe(): Promise<ProfileMe|null>{
  try {
    const res = await fetch(`${BASE}/profile/me`, { credentials:'include' });
    if(!res.ok) return null;
    return await res.json();
  } catch { return null; }
}
export async function notifications(): Promise<NotificationItem[]>{
  try{
    const res = await fetch(`${BASE}/notifications`, { credentials:'include' });
    if(!res.ok) return [];
    const data = await res.json();
    return Array.isArray(data?.items)? data.items: [];
  } catch { return []; }
}

// LocalStorage: избранные локации погоды
const LS_KEY = 'weather_favorites';
export interface WeatherFav { id:string; name:string; lat:number; lng:number; created_at:number; }
export function getWeatherFavs(): WeatherFav[]{
  try{
    return JSON.parse(localStorage.getItem(LS_KEY) || '[]');
  }catch{ return []; }
}
export function saveWeatherFav(f: WeatherFav){
  const arr = getWeatherFavs();
  const idx = arr.findIndex(x=>x.id===f.id);
  if(idx>=0) arr[idx] = f; else arr.push(f);
  localStorage.setItem(LS_KEY, JSON.stringify(arr));
}
export function removeWeatherFav(id: string){
  const arr = getWeatherFavs().filter(x=>x.id!==id);
  localStorage.setItem(LS_KEY, JSON.stringify(arr));
}
EOF

# ---------- src/components/Icon.tsx ----------
cat > "$FRONT/src/components/Icon.tsx" <<'EOF'
import React from 'react';
import { CONFIG, IconName } from '../config';

interface Props extends React.HTMLAttributes<HTMLSpanElement>{
  name: IconName | string;
  className?: string;
  fill?: 0|1;
  size?: number; // opsz
  weight?: number; // wght
  grade?: number; // GRAD
  title?: string;
}

export default function Icon({name,className,fill=0,size=24,weight=400,grade=0,...rest}:Props){
  const glyph = (CONFIG.Icons as any)[name] || name;
  const style: React.CSSProperties = {
    fontVariationSettings: `"FILL" ${fill}, "GRAD" ${grade}, "opsz" ${size}, "wght" ${weight}`
  };
  return (
    <span className={`material-symbols-rounded icon ${className||''}`} style={style} {...rest}>
      {glyph}
    </span>
  );
}
EOF

# ---------- src/components/Avatar.tsx ----------
cat > "$FRONT/src/components/Avatar.tsx" <<'EOF'
import React from 'react';
import { CONFIG } from '../config';

export default function Avatar({src,size=32}:{src?:string|null; size?:number}){
  const url = src || CONFIG.IMAGES.avatarDefault;
  return <img src={url} alt="" width={size} height={size}
    style={{borderRadius:'50%',border:'1px solid var(--stroke)',objectFit:'cover'}}/>;
}
EOF

# ---------- src/components/MediaGrid.tsx ----------
cat > "$FRONT/src/components/MediaGrid.tsx" <<'EOF'
import React from 'react';
import type { Media } from '../types';

export default function MediaGrid({items}:{items:Media[]|undefined}){
  if(!items || !items.length) return null;
  return (
    <div className="media-grid">
      {items.map((m,i)=> m.type==='video'
        ? <video key={i} src={m.url} controls playsInline/>
        : <img key={i} src={m.url} alt="" loading="lazy"/> )}
    </div>
  );
}
EOF

# ---------- src/components/PointPinCard.tsx ----------
cat > "$FRONT/src/components/PointPinCard.tsx" <<'EOF'
import React from 'react';
import { Point } from '../types';
import Icon from './Icon';

export default function PointPinCard({point,onOpen}:{point:Point; onOpen: (id:number|string)=>void}){
  const img = point.photo?.url || point.photos?.[0]?.url || '';
  return (
    <div className="glass-card card" style={{display:'grid',gridTemplateColumns:'88px 1fr',gap:12}}>
      {img ? <img src={img} alt="" style={{width:88,height:88,borderRadius:12,objectFit:'cover',border:'1px solid var(--stroke)'}}/> :
        <div style={{width:88,height:88,borderRadius:12,border:'1px dashed var(--stroke)',display:'grid',placeItems:'center',color:'var(--muted)'}}><Icon name="map"/></div>
      }
      <div>
        <div style={{fontWeight:600,marginBottom:6}}>{point.title||'Точка'}</div>
        <div className="small" style={{marginBottom:10}}>Тип: {point.type}</div>
        <button className="button ghost" onClick={()=>onOpen(point.id)}>Открыть</button>
      </div>
    </div>
  );
}
EOF

# ---------- src/components/Header.tsx ----------
cat > "$FRONT/src/components/Header.tsx" <<'EOF'
import React from 'react';
import Icon from './Icon';
import Avatar from './Avatar';
import { CONFIG } from '../config';

export default function Header({bonuses=0}:{bonuses?:number}){
  const go=(p:string)=>window.navigate?.(p);
  return (
    <div className="header glass">
      <div className="row">
        <a onClick={()=>go('/map')} style="cursor:pointer;display:flex;align-items:center;gap:8px">
          <img src={CONFIG.IMAGES.logo} alt="logo" width="28" height="28" style="border-radius:6px"/>
          <b>FishTrack</b>
        </a>
        <div className="right">
          <a className="badge" onClick={()=>go('/weather')} style={{cursor:'pointer'}}>
            <Icon name="weather" />
            <span>Погода</span>
          </a>
          <a onClick={()=>go('/alerts')} title="Уведомления" style={{cursor:'pointer'}}><Icon name="alerts"/></a>
          <a onClick={()=>go('/profile')} className="row" style={{gap:8,cursor:'pointer'}}>
            <Avatar src={null} />
            <span className="badge">{bonuses} бонусов</span>
          </a>
        </div>
      </div>
    </div>
  );
}
EOF

# ---------- src/components/BottomNav.tsx ----------
cat > "$FRONT/src/components/BottomNav.tsx" <<'EOF'
import React from 'react';
import Icon from './Icon';

const items = [
  {key:'map',   title:'Карта',  icon:'map'},
  {key:'feed',  title:'Лента',  icon:'feed'},
  {key:'alerts',title:'Оповещ.',icon:'alerts'},
  {key:'profile',title:'Профиль',icon:'profile'},
] as const;

export default function BottomNav({active}:{active:string}){
  const go=(p:string)=>window.navigate?.(p);
  return (
    <div className="tabs">
      <div className="glass inner">
        {items.map(it=>{
          const href = '/'+it.key;
          const isActive = active===href || (active==='/' && it.key==='map');
          return (
            <a key={it.key} className={`tab ${isActive?'active':''}`} onClick={()=>go(href)} style={{cursor:'pointer'}}>
              <Icon name={it.icon}/>
              <span>{it.title}</span>
            </a>
          );
        })}
      </div>
    </div>
  );
}
EOF

# ---------- src/pages/FeedScreen.tsx ----------
cat > "$FRONT/src/pages/FeedScreen.tsx" <<'EOF'
import React, {useEffect,useRef,useState} from 'react';
import { feed } from '../api';
import Icon from '../components/Icon';
import Avatar from '../components/Avatar';
import type { CatchItem } from '../types';

export default function FeedScreen(){
  const [items,setItems]=useState<CatchItem[]>([]);
  const [loading,setLoading]=useState(false);
  const [offset,setOffset]=useState(0);
  const ref = useRef<HTMLDivElement|null>(null);

  const load = async ()=>{
    if(loading) return;
    setLoading(true);
    try{
      const data = await feed(10, offset);
      setItems(prev => [...prev, ...data]);
      setOffset(prev => prev + data.length);
    } finally {
      setLoading(false);
    }
  };

  useEffect(()=>{ load(); },[]);
  useEffect(()=>{
    if(!ref.current) return;
    const io = new IntersectionObserver((e)=>{
      if(e[0].isIntersecting) load();
    }, {rootMargin:'400px'});
    io.observe(ref.current);
    return ()=>io.disconnect();
  },[ref.current]);

  const open = (id: number|string)=> window.navigate?.(`/catch/${id}`);

  return (
    <div className="container" style={{paddingBottom:90}}>
      <div className="grid" style={{marginTop:12}}>
        {items.map(it=>(
          <div key={String(it.id)} className="glass-card card">
            <div className="row" style={{justifyContent:'space-between'}}>
              <div className="row">
                <Avatar src={it.user_avatar}/>
                <div>
                  <div><b>{it.user_name||'Рыбак'}</b></div>
                  <div className="small">{new Date(it.created_at).toLocaleString()}</div>
                </div>
              </div>
              <Icon name="more" />
            </div>

            {it.media_url && (
              <div style={{margin:'12px -2px'}}>
                <img src={it.media_url} alt="" style={{width:'100%',borderRadius:12,border:'1px solid var(--stroke)'}} onClick={()=>open(it.id)}/>
              </div>
            )}

            <div className="row" style={{gap:12}}>
              <button className="badge" onClick={()=>open(it.id)}><Icon name="comment"/>{it.comments_count||0}</button>
              <span className="badge"><Icon name="like"/>{it.likes_count||0}</span>
              <a className="badge" onClick={()=>navigator.share?.({title:'Улов',url:location.origin+`/catch/${it.id}`})}><Icon name="share"/>Поделиться</a>
            </div>
          </div>
        ))}
        <div ref={ref} />
        {loading && <div className="small" style={{textAlign:'center',padding:20}}>Загрузка…</div>}
      </div>
    </div>
  );
}
EOF

# ---------- src/pages/CatchDetailPage.tsx ----------
cat > "$FRONT/src/pages/CatchDetailPage.tsx" <<'EOF'
import React,{useEffect,useState} from 'react';
import { catchById } from '../api';
import Icon from '../components/Icon';
import Avatar from '../components/Avatar';
import type { CatchItem } from '../types';

export default function CatchDetailPage({id}:{id:string}){
  const [item,setItem]=useState<CatchItem|null>(null);
  useEffect(()=>{
    catchById(id).then(setItem).catch(()=>setItem(null));
  },[id]);
  if(!item) return <div className="container" style={{padding:20}}>Загрузка…</div>;

  const goPlace = ()=> item.place_id && window.navigate?.(`/place/${item.place_id}`);

  return (
    <div className="container" style={{paddingBottom:90}}>
      <div className="glass card" style={{marginTop:12}}>
        <div className="row" style={{justifyContent:'space-between'}}>
          <div className="row">
            <Avatar src={item.user_avatar}/>
            <div>
              <div><b>{item.user_name}</b></div>
              <div className="small">{new Date(item.created_at).toLocaleString()}</div>
            </div>
          </div>
          <Icon name="more"/>
        </div>

        {item.media_url && <img src={item.media_url} alt="" style={{width:'100%',borderRadius:12,marginTop:12,border:'1px solid var(--stroke)'}}/>}

        <div className="grid" style={{marginTop:12}}>
          <div className="row"><b>Вид:</b>&nbsp;{item.species||'—'}</div>
          <div className="row"><b>Метод:</b>&nbsp;{item.method||'—'}</div>
          <div className="row"><b>Приманка:</b>&nbsp;{item.bait||'—'}</div>
          <div className="row"><b>Снасть:</b>&nbsp;{item.gear||'—'}</div>
          {item.caption && <div className="row">{item.caption}</div>}
          {item.place_id && <a className="badge" onClick={goPlace} style={{cursor:'pointer'}}><Icon name="map"/> К месту</a>}
        </div>
      </div>
    </div>
  );
}
EOF

# ---------- src/pages/AddCatchPage.tsx ----------
cat > "$FRONT/src/pages/AddCatchPage.tsx" <<'EOF'
import React, {useEffect, useRef, useState} from 'react';
import { addCatch, upload, weather } from '../api';
import Icon from '../components/Icon';

export default function AddCatchPage(){
  const [form,setForm]=useState<any>({ species:'', method:'', bait:'', gear:'', caption:'', lat:'', lng:'', caught_at:'' });
  const [files,setFiles]=useState<File[]>([]);
  const [pickMap,setPickMap]=useState(false);
  const mapRef = useRef<any>(null);
  const tempMarker = useRef<any>(null);
  const [hint,setHint] = useState<string|null>(null);

  const setField=(k:string,v:any)=> setForm((f:any)=>({...f,[k]:v}));

  // встраиваем выбор на карте
  useEffect(()=>{
    if(!pickMap) return;
    if(!mapRef.current){
      if(!(window as any).L){ setHint('Карта загружается…'); return; }
      const L = (window as any).L;
      const m = L.map('pick-map',{zoomControl:true}).setView([55.75,37.61], 11);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(m);
      m.on('click',(e:any)=>{
        const {lat,lng}=e.latlng;
        if(!tempMarker.current) tempMarker.current = L.marker([lat,lng]).addTo(m)
        else tempMarker.current.setLatLng([lat,lng]);
        setField('lat', lat.toFixed(6));
        setField('lng', lng.toFixed(6));
      });
      mapRef.current = m;
    } else {
      mapRef.current.invalidateSize();
    }
  },[pickMap]);

  const onFiles=(e:React.ChangeEvent<HTMLInputElement>)=>{
    const list = e.target.files ? Array.from(e.target.files) : [];
    setFiles(list);
  };

  const autofillWeather = async ()=>{
    const lat = parseFloat(form.lat), lng=parseFloat(form.lng);
    if(!lat || !lng) return setHint('Сначала укажите координаты');
    const dt = form.caught_at ? Math.floor(new Date(form.caught_at).getTime()/1000) : undefined;
    const w = await weather(lat,lng,dt);
    setHint(`Погода: ${w.temp_c??'—'}°C, ветер ${w.wind_ms??'—'} м/с`);
    setForm((f:any)=>({...f, weather_temp_c:w.temp_c, weather_wind_ms:w.wind_ms }));
  };

  const submit=async(e:React.FormEvent)=>{
    e.preventDefault();
    try{
      let media_url = undefined;
      if(files.length){
        const r = await upload(files);
        media_url = r.urls?.[0];
      }
      const payload = {...form, media_url};
      await addCatch(payload);
      setHint('Улов добавлен');
      setTimeout(()=>window.navigate?.('/feed'),800);
    }catch(err:any){
      setHint('Ошибка сохранения');
    }
  };

  return (
    <div className="container" style={{paddingBottom:90}}>
      <h2 style={{marginTop:12}}>Добавить улов</h2>
      <form className="form-grid glass card" onSubmit={submit}>
        <div className="form-inline">
          <input className="input" placeholder="Вид рыбы" value={form.species} onChange={e=>setField('species',e.target.value)}/>
          <input className="input" placeholder="Метод" value={form.method} onChange={e=>setField('method',e.target.value)}/>
        </div>
        <div className="form-inline">
          <input className="input" placeholder="Приманка" value={form.bait} onChange={e=>setField('bait',e.target.value)}/>
          <input className="input" placeholder="Снасть" value={form.gear} onChange={e=>setField('gear',e.target.value)}/>
        </div>
        <textarea className="input" placeholder="Комментарий" value={form.caption} onChange={e=>setField('caption',e.target.value)} />

        <div className="form-inline">
          <input className="input" placeholder="Широта" value={form.lat} onChange={e=>setField('lat',e.target.value)}/>
          <input className="input" placeholder="Долгота" value={form.lng} onChange={e=>setField('lng',e.target.value)}/>
        </div>

        <div className="row" style={{gap:10}}>
          <button type="button" className="button ghost" onClick={()=>setPickMap(v=>!v)}><Icon name="location"/> Выбрать на карте</button>
          <input type="datetime-local" className="input" value={form.caught_at} onChange={e=>setField('caught_at',e.target.value)} />
          <button type="button" className="button ghost" onClick={autofillWeather}><Icon name="weather"/> Подставить погоду</button>
        </div>

        {pickMap && <div id="pick-map" style={{height:300,borderRadius:12,overflow:'hidden',border:'1px solid var(--stroke)'}} />}

        <div>
          <label className="small">Фото/видео</label>
          <input type="file" multiple accept="image/*,video/*" onChange={onFiles}/>
        </div>

        <div className="row" style={{justifyContent:'flex-end',gap:10}}>
          <button type="button" className="button ghost" onClick={()=>window.navigate?.('/map')}>Отмена</button>
          <button type="submit" className="button primary">Сохранить</button>
        </div>
      </form>
      {hint && <div className="toast">{hint}</div>}
    </div>
  );
}
EOF

# ---------- src/pages/AddPlacePage.tsx ----------
cat > "$FRONT/src/pages/AddPlacePage.tsx" <<'EOF'
import React, {useEffect, useRef, useState} from 'react';
import { addPlace } from '../api';
import Icon from '../components/Icon';

export default function AddPlacePage(){
  const [form,setForm]=useState<any>({ title:'', type:'spot', lat:'', lng:'' });
  const [pickMap,setPickMap]=useState(false);
  const mapRef = useRef<any>(null);
  const tempMarker = useRef<any>(null);
  const [hint,setHint]=useState<string|null>(null);

  const setField=(k:string,v:any)=> setForm((f:any)=>({...f,[k]:v}));

  useEffect(()=>{
    if(!pickMap) return;
    if(!mapRef.current){
      if(!(window as any).L){ setHint('Карта загружается…'); return; }
      const L = (window as any).L;
      const m = L.map('pick-map2',{zoomControl:true}).setView([55.75,37.61], 11);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(m);
      m.on('click',(e:any)=>{
        const {lat,lng}=e.latlng;
        if(!tempMarker.current) tempMarker.current = L.marker([lat,lng]).addTo(m)
        else tempMarker.current.setLatLng([lat,lng]);
        setField('lat', lat.toFixed(6));
        setField('lng', lng.toFixed(6));
      });
      mapRef.current = m;
    } else {
      mapRef.current.invalidateSize();
    }
  },[pickMap]);

  const submit=async(e:React.FormEvent)=>{
    e.preventDefault();
    try{
      await addPlace({ ...form, lat:parseFloat(form.lat), lng:parseFloat(form.lng) });
      setHint('Точка добавлена');
      setTimeout(()=>window.navigate?.('/map'),700);
    }catch{
      setHint('Ошибка сохранения');
    }
  };

  return (
    <div className="container" style={{paddingBottom:90}}>
      <h2 style={{marginTop:12}}>Добавить точку</h2>
      <form className="form-grid glass card" onSubmit={submit}>
        <input className="input" placeholder="Название" value={form.title} onChange={e=>setField('title',e.target.value)}/>
        <select className="select" value={form.type} onChange={e=>setField('type',e.target.value)}>
          <option value="spot">Перспективное место</option>
          <option value="catch">Улов</option>
          <option value="shop">Магазин</option>
          <option value="slip">Слип</option>
          <option value="camp">Кемпинг</option>
        </select>
        <div className="form-inline">
          <input className="input" placeholder="Широта" value={form.lat} onChange={e=>setField('lat',e.target.value)}/>
          <input className="input" placeholder="Долгота" value={form.lng} onChange={e=>setField('lng',e.target.value)}/>
        </div>

        <div className="row" style={{gap:10}}>
          <button type="button" className="button ghost" onClick={()=>setPickMap(v=>!v)}><Icon name="location"/> Выбрать на карте</button>
        </div>
        {pickMap && <div id="pick-map2" style={{height:300,borderRadius:12,overflow:'hidden',border:'1px solid var(--stroke)'}} />}

        <div className="row" style={{justifyContent:'flex-end',gap:10}}>
          <button type="button" className="button ghost" onClick={()=>window.navigate?.('/map')}>Отмена</button>
          <button type="submit" className="button primary">Сохранить</button>
        </div>
      </form>
      {hint && <div className="toast">{hint}</div>}
    </div>
  );
}
EOF

# ---------- src/pages/MapScreen.tsx ----------
cat > "$FRONT/src/pages/MapScreen.tsx" <<'EOF'
import React,{useEffect,useRef,useState} from 'react';
import { points, getWeatherFavs, saveWeatherFav } from '../api';
import type { Point } from '../types';
import PointPinCard from '../components/PointPinCard';
import Icon from '../components/Icon';

export default function MapScreen(){
  const [items,setItems]=useState<Point[]>([]);
  const [sel,setSel]=useState<Point|null>(null);
  const [clickLatLng,setClickLatLng]=useState<{lat:number,lng:number}|null>(null);
  const mapRef = useRef<any>(null);
  const markersRef = useRef<any[]>([]);
  const clickMarkerRef = useRef<any|null>(null);
  const [fabOpen,setFabOpen]=useState(false);
  const [toast,setToast]=useState<string|null>(null);

  const openPlace=(id:number|string)=> window.navigate?.(`/place/${id}`);

  useEffect(()=>{
    if(!(window as any).L) return; // подождать загрузки Leaflet
    if(mapRef.current) return;

    const L = (window as any).L;
    const m = L.map('map',{zoomControl:true}).setView([55.75,37.61], 10);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(m);

    m.on('moveend', ()=> loadBounds());
    m.on('click',(e:any)=> {
      const {lat,lng}=e.latlng;
      setClickLatLng({lat,lng});
      if(!clickMarkerRef.current) clickMarkerRef.current = L.marker([lat,lng]).addTo(m);
      else clickMarkerRef.current.setLatLng([lat,lng]);
    });

    mapRef.current = m;
    loadBounds();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  },[]);

  async function loadBounds(){
    if(!mapRef.current) return;
    const b = mapRef.current.getBounds();
    const bbox:[number,number,number,number] = [b.getWest(), b.getSouth(), b.getEast(), b.getNorth()];
    const data = await points({limit:500,bbox});
    setItems(data);
    // markers
    const L = (window as any).L;
    markersRef.current.forEach(m=>m.remove());
    markersRef.current = [];
    data.forEach(p=>{
      const mk = L.marker([p.lat,p.lng]).addTo(mapRef.current)
        .on('click',()=> setSel(p));
      markersRef.current.push(mk);
    });
  }

  const saveWeatherPoint = ()=>{
    if(!clickLatLng) return;
    const id = `${clickLatLng.lat.toFixed(4)},${clickLatLng.lng.toFixed(4)}`;
    saveWeatherFav({ id, name:`Метка ${id}`, lat:clickLatLng.lat, lng:clickLatLng.lng, created_at:Date.now() });
    setToast('Локация добавлена в Погоду');
    setTimeout(()=>setToast(null),1200);
  };

  return (
    <div className="map-wrap">
      <div id="map"></div>

      {/* нижняя стеклянная панель */}
      <div className="map-overlay">
        <div className="panel glass">
          {!sel && <div className="small">Нажмите на пин чтобы посмотреть место. Нажмите на карту — поставится временная метка.</div>}
          {sel && <PointPinCard point={sel} onOpen={openPlace}/>}
        </div>
      </div>

      {/* FAB */}
      <div className="fab">
        {fabOpen && (
          <div className="fab-menu">
            <div className="action" onClick={()=>window.navigate?.('/add-catch')} style={{cursor:'pointer'}}>
              <span className="chip">Добавить улов</span>
              <div className="btn"><Icon name="addCatch"/></div>
            </div>
            <div className="action" onClick={()=>window.navigate?.('/add-place')} style={{cursor:'pointer'}}>
              <span className="chip">Добавить точку</span>
              <div className="btn"><Icon name="addPlace"/></div>
            </div>
            {clickLatLng && (
              <div className="action" onClick={saveWeatherPoint} style={{cursor:'pointer'}}>
                <span className="chip">Сохранить локацию погоды</span>
                <div className="btn"><Icon name="bookmark"/></div>
              </div>
            )}
          </div>
        )}
        <button className="btn" onClick={()=>setFabOpen(v=>!v)}><Icon name="plus" weight={700}/></button>
      </div>

      {toast && <div className="toast">{toast}</div>}
    </div>
  );
}
EOF

# ---------- src/pages/PlaceDetailPage.tsx ----------
cat > "$FRONT/src/pages/PlaceDetailPage.tsx" <<'EOF'
import React from 'react';

export default function PlaceDetailPage({id}:{id:string}){
  return (
    <div className="container" style={{padding:'12px 16px 90px'}}>
      <div className="glass card">
        <h2>Место #{id}</h2>
        <div className="small">Страница места (карточка, список уловов — будет расширяться).</div>
      </div>
    </div>
  );
}
EOF

# ---------- src/pages/NotificationsPage.tsx ----------
cat > "$FRONT/src/pages/NotificationsPage.tsx" <<'EOF'
import React,{useEffect,useState} from 'react';
import { notifications } from '../api';

export default function NotificationsPage(){
  const [items,setItems]=useState<any[]>([]);
  useEffect(()=>{ notifications().then(setItems); },[]);
  return (
    <div className="container" style={{padding:'12px 16px 90px'}}>
      <h2>Уведомления</h2>
      <div className="grid" style={{marginTop:12}}>
        {items.map((n,i)=>(
          <div key={i} className="glass-card card">
            <div><b>{n.title||'—'}</b></div>
            <div className="small">{n.body||''}</div>
            <div className="small">{n.created_at ? new Date(n.created_at).toLocaleString() : ''}</div>
          </div>
        ))}
        {!items.length && <div className="small">Пока пусто</div>}
      </div>
    </div>
  );
}
EOF

# ---------- src/pages/ProfilePage.tsx ----------
cat > "$FRONT/src/pages/ProfilePage.tsx" <<'EOF'
import React,{useEffect,useState} from 'react';
import { profileMe } from '../api';
import Avatar from '../components/Avatar';

export default function ProfilePage(){
  const [me,setMe]=useState<any|null>(null);
  useEffect(()=>{ profileMe().then(setMe); },[]);
  return (
    <div className="container" style={{padding:'12px 16px 90px'}}>
      <div className="glass card" style={{display:'flex',gap:14,alignItems:'center'}}>
        <Avatar src={me?.avatar} size={56}/>
        <div>
          <div><b>{me?.name||'Гость'}</b></div>
          <div className="small">Бонусов: {me?.bonuses ?? 0}</div>
        </div>
      </div>
      <div className="grid" style={{marginTop:12}}>
        <a className="glass-card card" onClick={()=>window.navigate?.('/feed')} style={{cursor:'pointer'}}>Мои уловы</a>
        <a className="glass-card card" onClick={()=>window.navigate?.('/weather')} style={{cursor:'pointer'}}>Мои локации погоды</a>
      </div>
    </div>
  );
}
EOF

# ---------- src/pages/WeatherPage.tsx ----------
cat > "$FRONT/src/pages/WeatherPage.tsx" <<'EOF'
import React,{useEffect,useState} from 'react';
import { getWeatherFavs, removeWeatherFav, weather } from '../api';
import Icon from '../components/Icon';

interface Model {
  id:string; name:string; lat:number; lng:number;
  temp_c?: number|null;
  wind_ms?: number|null;
}

export default function WeatherPage(){
  const [items,setItems]=useState<Model[]>([]);
  const [loading,setLoading]=useState(false);

  const load = async ()=>{
    setLoading(true);
    const favs = getWeatherFavs();
    const enriched: Model[] = [];
    for(const f of favs){
      const w = await weather(f.lat, f.lng);
      enriched.push({ ...f, temp_c: w.temp_c??null, wind_ms: w.wind_ms??null });
    }
    setItems(enriched);
    setLoading(false);
  };

  useEffect(()=>{ load(); },[]);

  const del = (id:string)=>{
    removeWeatherFav(id);
    load();
  };

  return (
    <div className="container" style={{paddingBottom:90}}>
      <h2 style={{marginTop:12}}>Погода</h2>
      <div className="grid" style={{marginTop:12}}>
        {items.map(it=>(
          <div key={it.id} className="glass-card card row" style={{justifyContent:'space-between'}}>
            <div>
              <div><b>{it.name}</b></div>
              <div className="small">{it.lat.toFixed(4)}, {it.lng.toFixed(4)}</div>
            </div>
            <div className="row" style={{gap:12}}>
              <span className="badge"><Icon name="temp"/>{it.temp_c??'—'}°C</span>
              <span className="badge"><Icon name="wind"/>{it.wind_ms??'—'} м/с</span>
              <a className="badge" onClick={()=>del(it.id)} style={{cursor:'pointer'}}>Удалить</a>
            </div>
          </div>
        ))}
        {!items.length && !loading && <div className="small">Сохраните локацию на карте: нажмите на карту → «Сохранить локацию погоды»</div>}
        {loading && <div className="small">Обновляем…</div>}
      </div>
    </div>
  );
}
EOF

# ---------- src/App.tsx ----------
cat > "$FRONT/src/App.tsx" <<'EOF'
import React,{useEffect,useMemo,useState} from 'react';
import './styles/app.css';
import Header from './components/Header';
import BottomNav from './components/BottomNav';

import MapScreen from './pages/MapScreen';
import FeedScreen from './pages/FeedScreen';
import CatchDetailPage from './pages/CatchDetailPage';
import AddCatchPage from './pages/AddCatchPage';
import AddPlacePage from './pages/AddPlacePage';
import NotificationsPage from './pages/NotificationsPage';
import ProfilePage from './pages/ProfilePage';
import WeatherPage from './pages/WeatherPage';
import PlaceDetailPage from './pages/PlaceDetailPage';

function useRouter(){
  const [path,setPath]=useState<string>(location.pathname || '/');
  useEffect(()=>{
    (window as any).navigate = (p:string)=>{
      if(p===path) return;
      history.pushState({},'',p);
      setPath(p);
      // авто-скролл вверх
      window.scrollTo({top:0,behavior:'instant' as any});
    };
    const onPop=()=>setPath(location.pathname || '/');
    window.addEventListener('popstate', onPop);
    return ()=>window.removeEventListener('popstate', onPop);
  },[path]);
  return path;
}

export default function App(){
  const path = useRouter();

  const page = useMemo(()=>{
    // деталка
    const catchMatch = path.match(/^\/catch\/(\d+)/);
    if(catchMatch) return <CatchDetailPage id={catchMatch[1]} />;

    const placeMatch = path.match(/^\/place\/(\d+)/);
    if(placeMatch) return <PlaceDetailPage id={placeMatch[1]} />;

    switch(true){
      case path==='/':
      case path.startsWith('/map'): return <MapScreen/>;
      case path.startsWith('/feed'): return <FeedScreen/>;
      case path.startsWith('/add-catch'): return <AddCatchPage/>;
      case path.startsWith('/add-place'): return <AddPlacePage/>;
      case path.startsWith('/alerts'): return <NotificationsPage/>;
      case path.startsWith('/profile'): return <ProfilePage/>;
      case path.startsWith('/weather'): return <WeatherPage/>;
      default: return <div className="container" style={{padding:20}}>Страница не найдена</div>;
    }
  },[path]);

  // какая вкладка активна для нижнего меню
  const activeTab = useMemo(()=>{
    if(path.startsWith('/feed')) return '/feed';
    if(path.startsWith('/alerts')) return '/alerts';
    if(path.startsWith('/profile')) return '/profile';
    return '/map';
  },[path]);

  return (
    <div>
      <Header bonuses={0}/>
      {page}
      <BottomNav active={activeTab}/>
    </div>
  );
}
EOF

# ---------- src/main.tsx ----------
cat > "$FRONT/src/main.tsx" <<'EOF'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';

const container = document.getElementById('root')!;
createRoot(container).render(<App />);
EOF

echo "✅ Готово. Файлы обновлены.
Что сделано:
 - Вернул «живую» карту Leaflet + стеклянные панели (glassmorphism).
 - Исправил API-вызовы, защитил от r.map is not a function (всегда ожидаем {items[]}).
 - Добавил FAB (плюс) с действиями: Добавить улов / Добавить точку / Сохранить локацию погоды (по клику на карте).
 - Добавил выбор координат на карте в формах добавления улова/точки.
 - Страница Погоды показывает сохранённые локации и подгружает текущую temp/wind.
 - Шапка: ссылка на Погоду, Уведомления, Профиль; Низ: меню вкладок.
 - Иконки через Material Symbols; имя иконки берётся из config.ts.
 - Маркер на карте: клик по пину -> карточка места с превью и кнопкой перехода на страницу места.

Проверь:
 - Nginx настроен на SPA (все маршруты -> index.html).
 - В .env фронта (или через Vite) при необходимости выставь VITE_API_BASE=https://api.fishtrackpro.ru/api/v1
 - В бэке включён CORS для домена www.fishtrackpro.ru.
"