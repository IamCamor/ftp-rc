#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
SRC="$ROOT/src"
[ -d "$ROOT/frontend/src" ] && SRC="$ROOT/frontend/src"

mkdir -p "$SRC/components" "$SRC/pages" "$SRC/styles" "$SRC/utils" "$SRC/assets"

############################################
# 0) БАЗОВЫЕ АССЕТЫ (можешь заменить своими)
############################################
# Минимальные заглушки
cat > "$SRC/assets/logo.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="240" height="64" viewBox="0 0 240 64" fill="none">
  <rect width="240" height="64" rx="12" fill="#0ea5e9"/>
  <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-family="system-ui, -apple-system" font-size="24" fill="white">FishTrack Pro</text>
</svg>
SVG

# Можно положить свой default-avatar.png в public, но дадим запасной путь
# Если у тебя уже есть свой файл – этот блок можно пропустить.

############################################
# 1) config.ts — единый конфиг приложения
############################################
cat > "$SRC/config.ts" <<'TS'
export type AppConfig = {
  apiBase: string;        // База API (по ТЗ: /api/v1)
  siteBase: string;       // База сайта (для ссылок)
  images: {
    logoUrl: string;
    defaultAvatar: string;
    backgroundPattern: string;
  };
  icons: {
    like: string;
    comment: string;
    share: string;
    map: string;
    add: string;
    alerts: string;
    profile: string;
    weather: string;
    home: string;
  };
};

const config: AppConfig = {
  apiBase: 'https://api.fishtrackpro.ru/api/v1',
  siteBase: 'https://www.fishtrackpro.ru',
  images: {
    logoUrl: '/assets/logo.svg',
    defaultAvatar: '/assets/default-avatar.png', // Подложка; если нет — отменится на /src/assets
    backgroundPattern: '/assets/bg-pattern.png',
  },
  icons: {
    like: 'favorite',
    comment: 'chat_bubble',
    share: 'share',
    map: 'map',
    add: 'add_location_alt',
    alerts: 'notifications',
    profile: 'account_circle',
    weather: 'partly_cloudy_day',
    home: 'home',
  },
};

export default config;
TS

############################################
# 2) styles/app.css — минимальная тема + glass
############################################
cat > "$SRC/styles/app.css" <<'CSS'
:root{
  --bg: #0b1220;
  --card: rgba(255,255,255,.06);
  --stroke: rgba(255,255,255,.14);
  --text: #e6f1ff;
  --muted: rgba(230,241,255,.75);
  --accent: #0ea5e9;
}
*{box-sizing:border-box}
html,body,#root{height:100%}
body{
  margin:0;
  color:var(--text);
  background:
    radial-gradient(1200px 600px at 20% -10%, rgba(14,165,233,.25), transparent 50%),
    radial-gradient(800px 500px at 120% 10%, rgba(99,102,241,.22), transparent 50%),
    linear-gradient(180deg, #0b1220 0%, #0b1220 100%);
  font-family: Inter, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, "Apple Color Emoji","Segoe UI Emoji";
}
a{color:inherit;text-decoration:none}
button{font:inherit}
.container{padding:16px}
.h1{font-size:1.5rem;margin:0 0 12px}
.h2{font-size:1.25rem;margin:0 0 10px}
.muted{color:var(--muted)}
.row{display:flex;gap:8px;align-items:center}
.grid{display:grid;gap:12px}

.glass{
  background: var(--card);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid var(--stroke);
}
.card{border-radius:14px;padding:12px}

.btn{
  display:inline-flex;align-items:center;gap:8px;
  padding:10px 14px;border-radius:12px;
  background:rgba(255,255,255,.08);
  border:1px solid rgba(255,255,255,.18);
  color:var(--text);cursor:pointer
}
.btn.primary{background:var(--accent);border-color:transparent;color:white}
.btn.full{width:100%;justify-content:center}

.input, .select, .textarea{
  width:100%;padding:10px 12px;border-radius:12px;
  background:rgba(255,255,255,.06);
  border:1px solid rgba(255,255,255,.2);color:var(--text)
}

.header{
  position:sticky;top:0;z-index:20;
  display:flex;align-items:center;justify-content:space-between;
  padding:8px 12px;border-bottom:1px solid var(--stroke)
}
.header .left,.header .right{display:flex;align-items:center;gap:8px}

.bottom-nav{
  position:sticky;bottom:0;z-index:20;
  display:grid;grid-template-columns:repeat(5,1fr);gap:6px;
  padding:8px;border-top:1px solid var(--stroke)
}
.bottom-link{
  display:flex;flex-direction:column;align-items:center;gap:4px;
  padding:8px;border-radius:12px;background:rgba(255,255,255,.04)
}
.bottom-link.active{background:rgba(255,255,255,.12)}

.media-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:6px}
.media-grid img{width:100%;aspect-ratio:1/1;object-fit:cover;border-radius:10px}
.leaflet-container{width:100%;height:calc(100svh - 140px);border-radius:14px;overflow:hidden}
CSS

############################################
# 3) utils/leafletLoader.ts — динамическая загрузка Leaflet
############################################
cat > "$SRC/utils/leafletLoader.ts" <<'TS'
let cached: any = null;
export async function loadLeaflet() {
  if (cached) return cached;
  const L = await import('leaflet');
  // Без CSS Leaflet маркеры не видны — оставим подсказку в README
  return cached = L;
}
TS

############################################
# 4) components/Icon.tsx — Material Symbols
############################################
cat > "$SRC/components/Icon.tsx" <<'TS'
import React from 'react';

type Props = {
  name: string;
  size?: number | string; // 24 по умолчанию
  className?: string;
  title?: string;
};
const Icon: React.FC<Props> = ({ name, size=24, className='', title }) => {
  const s = typeof size === 'number' ? `${size}px` : size;
  return (
    <span className={`material-symbols-rounded ${className}`} style={{fontSize:s, lineHeight:1}} aria-hidden title={title}>
      {name}
    </span>
  );
};

export default Icon;
TS

############################################
# 5) components/Header.tsx
############################################
cat > "$SRC/components/Header.tsx" <<'TS'
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';
import Icon from './Icon';

const Header: React.FC = () => {
  const { pathname } = useLocation();
  const logo = config?.images?.logoUrl || '/src/assets/logo.svg';
  return (
    <header className="header glass">
      <div className="left">
        <Link to="/feed" className="row" aria-label="На главную">
          <img src={logo} alt="Logo" style={{height:28}} />
        </Link>
      </div>
      <div className="right">
        <Link to="/weather" className="btn" title="Погода">
          <Icon name={config.icons.weather} /> <span className="hide-sm">Погода</span>
        </Link>
        <Link to="/add/catch" className="btn primary" title="Добавить улов">
          <Icon name={config.icons.add} /> <span className="hide-sm">Улов</span>
        </Link>
      </div>
    </header>
  );
};

export default Header;
TS

############################################
# 6) components/BottomNav.tsx
############################################
cat > "$SRC/components/BottomNav.tsx" <<'TS'
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';
import Icon from './Icon';

const BottomNav: React.FC = () => {
  const { pathname } = useLocation();
  const is = (p: string) => pathname.startsWith(p);
  const Item: React.FC<{to:string; icon:string; label:string}> = ({to, icon, label}) => (
    <Link to={to} className={`bottom-link glass ${is(to)?'active':''}`}>
      <Icon name={icon} />
      <small>{label}</small>
    </Link>
  );
  return (
    <nav className="bottom-nav glass">
      <Item to="/feed" icon={config.icons.home} label="Лента" />
      <Item to="/map" icon={config.icons.map} label="Карта" />
      <Item to="/add/place" icon={config.icons.add} label="Место" />
      <Item to="/alerts" icon={config.icons.alerts} label="Оповещения" />
      <Item to="/profile" icon={config.icons.profile} label="Профиль" />
    </nav>
  );
};

export default BottomNav;
TS

############################################
# 7) components/Avatar.tsx (простая аватарка)
############################################
cat > "$SRC/components/Avatar.tsx" <<'TS'
import React from 'react';
import config from '../config';

const Avatar: React.FC<{src?:string; size?:number; alt?:string}> = ({src, size=40, alt='avatar'}) => {
  const fallback = config?.images?.defaultAvatar || '/assets/default-avatar.png';
  return (
    <img
      src={src || fallback}
      alt={alt}
      style={{ width:size, height:size, borderRadius:'50%', objectFit:'cover', border:'1px solid rgba(255,255,255,.2)'}}
    />
  );
};
export default Avatar;
TS

############################################
# 8) components/MediaGrid.tsx
############################################
cat > "$SRC/components/MediaGrid.tsx" <<'TS'
import React from 'react';

const MediaGrid: React.FC<{items: Array<{url:string}>}> = ({items}) => {
  const list = Array.isArray(items) ? items : [];
  if (!list.length) return null;
  return (
    <div className="media-grid">
      {list.map((m,i)=>(
        <img key={i} src={m.url} alt={`media-${i}`} loading="lazy" />
      ))}
    </div>
  );
};
export default MediaGrid;
TS

############################################
# 9) components/PointPinCard.tsx — карточка пина
############################################
cat > "$SRC/components/PointPinCard.tsx" <<'TS'
import React from 'react';
import { Link } from 'react-router-dom';

type Point = { id?: number|string; lat:number; lng:number; title?:string; photos?:string[]; kind?: 'place'|'catch' };
const PointPinCard: React.FC<{p:Point}> = ({p}) => {
  const img = p.photos?.[0];
  const link = p.kind === 'catch' ? `/catch/${p.id}` : `/place/${p.id}`;
  return (
    <div className="glass card" style={{display:'flex', gap:10}}>
      {img && <img src={img} alt="" style={{width:72, height:72, objectFit:'cover', borderRadius:8}} />}
      <div style={{flex:1}}>
        <div style={{fontWeight:600}}>{p.title || 'Точка'}</div>
        <div className="muted" style={{fontSize:12}}>
          {p.lat.toFixed(4)}, {p.lng.toFixed(4)}
        </div>
        {p.id && <Link to={link} className="btn" style={{marginTop:8}}>Открыть</Link>}
      </div>
    </div>
  );
};
export default PointPinCard;
TS

############################################
# 10) api.ts — единый клиент + авторизация + helpers
############################################
cat > "$SRC/api.ts" <<'TS'
import config from './config';

type HttpOptions = {
  method?: 'GET'|'POST'|'PUT'|'PATCH'|'DELETE';
  body?: any;
  auth?: boolean;
  headers?: Record<string,string>;
};

function getToken(): string | null {
  try { return localStorage.getItem('token'); } catch { return null; }
}

async function http<T=any>(url: string, opts: HttpOptions = {}): Promise<T> {
  const { method='GET', body, auth=true, headers={} } = opts;
  const token = getToken();

  const res = await fetch(url, {
    method,
    mode: 'cors',
    credentials: 'omit', // CORS на бэке уже ок — передаём токен заголовком
    headers: {
      'Accept': 'application/json',
      ...(body ? {'Content-Type': 'application/json'} : {}),
      ...(auth && token ? { 'Authorization': `Bearer ${token}` } : {}),
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (res.status === 204) return undefined as unknown as T;

  let data: any = null;
  const text = await res.text().catch(()=> '');
  try { data = text ? JSON.parse(text) : null; } catch { data = text; }

  if (!res.ok) {
    const msg = (data && (data.message || data.error)) || `${res.status} ${res.statusText}`;
    throw new Error(msg);
  }
  return data as T;
}

function unwrap<T=any>(x: any, fallback: T): T {
  if (x == null) return fallback;
  if (Array.isArray(x)) return x as T;
  if (typeof x === 'object' && Array.isArray((x as any).data)) return (x as any).data as T;
  return x as T;
}

const base = config.apiBase;

// feed
export async function feed(params: {limit?: number; offset?: number} = {}) {
  const q = new URLSearchParams();
  if (params.limit) q.set('limit', String(params.limit));
  if (params.offset) q.set('offset', String(params.offset));
  const r = await http<any>(`${base}/feed${q.toString()?`?${q.toString()}`:''}`);
  return unwrap<any[]>(r, []);
}

// map points
export async function points(bbox?: string, limit = 500) {
  const q = new URLSearchParams();
  q.set('limit', String(limit));
  if (bbox) q.set('bbox', bbox);
  const r = await http<any>(`${base}/map/points?${q.toString()}`);
  return unwrap<any[]>(r, []);
}

// catch & place details
export async function catchById(id: string|number){ return await http<any>(`${base}/catch/${id}`); }
export async function placeById(id: string|number){ return await http<any>(`${base}/place/${id}`); }

// comments / likes (потребуют рабочие маршруты на бэке)
export async function addCatchComment(id:number|string, text:string){
  return await http(`${base}/catch/${id}/comments`, {method:'POST', body:{text}});
}
export async function likeCatch(id:number|string){
  return await http(`${base}/catch/${id}/like`, {method:'POST'});
}

// notifications
export async function notifications() {
  const r = await http<any>(`${base}/notifications`);
  return unwrap<any[]>(r, []);
}

// profile
export async function profileMe(){ return await http<any>(`${base}/profile/me`); }

// weather favs (локально)
export function getWeatherFavs(): Array<{lat:number; lng:number; title?:string; id?:string|number}> {
  try {
    const raw = localStorage.getItem('weather_favs');
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}
export function saveWeatherFav(p: {lat:number; lng:number; title?:string}) {
  const list = getWeatherFavs();
  list.push(p);
  try { localStorage.setItem('weather_favs', JSON.stringify(list)); } catch {}
  return list;
}

// add catch/place (формы)
export async function addCatch(payload: {
  species?: string; length?: number; weight?: number;
  style?: string; lure?: string; tackle?: string;
  notes?: string; photo_url?: string;
  lat?: number; lng?: number; caught_at?: string; // ISO
  privacy?: 'all'|'friends'|'private';
}) {
  return await http(`${base}/catch`, {method:'POST', body: payload});
}

export async function addPlace(payload: {
  title: string; description?: string;
  lat: number; lng: number;
  photos?: string[];
}) {
  return await http(`${base}/place`, {method:'POST', body: payload});
}

// auth
export async function login(email: string, password: string) {
  const r = await http<{token:string}>(`${base}/auth/login`, {method:'POST', body:{email,password}, auth:false});
  if (r?.token) localStorage.setItem('token', r.token);
  return r;
}
export async function register(name: string, email: string, password: string) {
  const r = await http<{token:string}>(`${base}/auth/register`, {method:'POST', body:{name,email,password}, auth:false});
  if (r?.token) localStorage.setItem('token', r.token);
  return r;
}
export function logout(){ try { localStorage.removeItem('token'); } catch {} }
export function isAuthed(){ return !!getToken(); }
TS

############################################
# 11) pages/FeedScreen.tsx
############################################
cat > "$SRC/pages/FeedScreen.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { feed } from '../api';
import Icon from '../components/Icon';
import config from '../config';
import { Link } from 'react-router-dom';

const FeedScreen: React.FC = () => {
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    feed({limit:10, offset:0})
      .then((r)=> Array.isArray(r)? setItems(r) : setItems([]))
      .catch((e)=> setErr(e.message||'Ошибка загрузки ленты'));
  },[]);

  return (
    <div className="container">
      <h2 className="h2">Лента</h2>
      {err && <div className="card glass" style={{color:'#ffb4b4'}}>{err}</div>}

      {items.map((it, i)=>(
        <div key={i} className="glass card">
          <div className="row" style={{justifyContent:'space-between'}}>
            <div className="row">
              <strong>{it.user_name || 'рыбак'}</strong>
              <span className="muted">· {new Date(it.created_at||Date.now()).toLocaleString()}</span>
            </div>
            <div className="row">
              <button className="btn"><Icon name={config.icons.like} /> {it.likes_count ?? 0}</button>
              <Link className="btn" to={`/catch/${it.id}`}><Icon name={config.icons.comment} /> {it.comments_count ?? 0}</Link>
              <button className="btn"><Icon name={config.icons.share} /> Поделиться</button>
            </div>
          </div>
          {it.media_url && <img src={it.media_url} alt="" style={{width:'100%', borderRadius:12, marginTop:8}} />}
          {it.caption && <div style={{marginTop:8}}>{it.caption}</div>}
        </div>
      ))}
    </div>
  );
};
export default FeedScreen;
TS

############################################
# 12) pages/MapScreen.tsx — Leaflet + клик для добавления в погоду
############################################
cat > "$SRC/pages/MapScreen.tsx" <<'TS'
import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { points, saveWeatherFav } from '../api';
import { loadLeaflet } from '../utils/leafletLoader';
import PointPinCard from '../components/PointPinCard';
import Icon from '../components/Icon';
import config from '../config';

const MapScreen: React.FC = () => {
  const nav = useNavigate();
  const mapRef = useRef<any>(null);
  const layerRef = useRef<any>(null);
  const [list, setList] = useState<any[]>([]);
  const [selected, setSelected] = useState<any|null>(null);
  const mapEl = useRef<HTMLDivElement>(null);

  // загрузка точек
  useEffect(()=>{
    async function run(){
      try{
        const arr = await points(undefined, 500);
        setList(Array.isArray(arr)? arr : []);
      }catch(e){ console.error('points load error', e); }
    }
    run();
  },[]);

  // инициализация карты
  useEffect(()=>{
    let map:any, L:any, markers:any;
    async function init(){
      if (!mapEl.current) return;
      L = await loadLeaflet();

      map = L.map(mapEl.current).setView([55.75, 37.62], 10);
      mapRef.current = map;

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{
        attribution:'© OpenStreetMap',
      }).addTo(map);

      markers = L.layerGroup().addTo(map);
      layerRef.current = markers;

      // Клик по карте — добавить в избранную погоду
      map.on('click', (ev:any)=>{
        const { lat, lng } = ev.latlng;
        saveWeatherFav({lat, lng, title:`Выбранная точка`});
        alert('Точка добавлена в Погоду');
      });
    }
    init();
    return ()=>{ if (mapRef.current) mapRef.current.remove(); };
  },[]);

  // отрисовка маркеров
  useEffect(()=>{
    (async ()=>{
      const L = await loadLeaflet();
      const g = layerRef.current;
      if (!g) return;
      g.clearLayers();

      (Array.isArray(list) ? list : []).forEach((p:any)=>{
        const m = L.marker([p.lat, p.lng]).addTo(g);
        m.on('click', ()=>{
          setSelected(p);
        });
      });
    })();
  },[list]);

  return (
    <div className="container">
      <div className="row" style={{justifyContent:'space-between', marginBottom:8}}>
        <h2 className="h2">Карта</h2>
        <div className="row" style={{gap:6}}>
          <button className="btn" onClick={()=>nav('/add/place')} title="Добавить место">
            <Icon name={config.icons.add} /> Место
          </button>
          <button className="btn" onClick={()=>nav('/add/catch')} title="Добавить улов">
            <Icon name={config.icons.add} /> Улов
          </button>
        </div>
      </div>

      <div ref={mapEl} className="leaflet-container glass" />

      {selected && (
        <div style={{marginTop:12}}>
          <PointPinCard p={{
            id: selected.id,
            lat: selected.lat,
            lng: selected.lng,
            title: selected.title || selected.name,
            photos: selected.photos,
            kind: selected.type || 'place'
          }}/>
        </div>
      )}
    </div>
  );
};
export default MapScreen;
TS

############################################
# 13) pages/CatchDetailPage.tsx
############################################
cat > "$SRC/pages/CatchDetailPage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { catchById, addCatchComment } from '../api';
import Icon from '../components/Icon';
import config from '../config';

const CatchDetailPage: React.FC = () => {
  const { id } = useParams();
  const [data, setData] = useState<any>(null);
  const [err, setErr] = useState('');
  const [text, setText] = useState('');

  useEffect(()=>{
    if (!id) return;
    catchById(id).then(setData).catch((e)=> setErr(e.message||'Ошибка'));
  },[id]);

  async function submitComment(e:React.FormEvent){
    e.preventDefault();
    try{
      await addCatchComment(String(id), text);
      setText('');
      // простая перезагрузка данных
      const d = await catchById(String(id));
      setData(d);
    }catch(ex:any){
      alert(ex?.message||'Не удалось добавить комментарий');
    }
  }

  if (err) return <div className="container"><div className="card glass" style={{color:'#ffb4b4'}}>{err}</div></div>;
  if (!data) return <div className="container"><div className="card glass">Загрузка…</div></div>;

  return (
    <div className="container">
      <h2 className="h2">Улов #{id}</h2>
      {data.photo_url && <img src={data.photo_url} alt="" style={{width:'100%', borderRadius:12}} />}
      {data.caption && <div style={{marginTop:8}}>{data.caption}</div>}

      <div className="row" style={{gap:8, marginTop:10}}>
        <button className="btn"><Icon name={config.icons.like} /> {data.likes_count ?? 0}</button>
        <button className="btn"><Icon name={config.icons.share} /> Поделиться</button>
      </div>

      <h3 style={{marginTop:16}}>Комментарии</h3>
      <div className="grid">
        {(data.comments || []).map((c:any, i:number)=>(
          <div key={i} className="card glass">
            <div className="row" style={{justifyContent:'space-between'}}>
              <strong>{c.user_name || 'гость'}</strong>
              <span className="muted">{new Date(c.created_at||Date.now()).toLocaleString()}</span>
            </div>
            <div style={{marginTop:6}}>{c.text}</div>
          </div>
        ))}
      </div>

      <form className="card glass" style={{marginTop:12}} onSubmit={submitComment}>
        <textarea className="textarea" placeholder="Ваш комментарий…" value={text} onChange={e=>setText(e.target.value)} required />
        <button className="btn primary" type="submit">Отправить</button>
      </form>
    </div>
  );
};
export default CatchDetailPage;
TS

############################################
# 14) pages/PlaceDetailPage.tsx
############################################
cat > "$SRC/pages/PlaceDetailPage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { placeById } from '../api';
import MediaGrid from '../components/MediaGrid';

const PlaceDetailPage: React.FC = () => {
  const { id } = useParams();
  const [data, setData] = useState<any>(null);
  const [err, setErr] = useState('');

  useEffect(()=>{
    if (!id) return;
    placeById(id).then(setData).catch((e)=> setErr(e.message||'Ошибка'));
  },[id]);

  if (err) return <div className="container"><div className="card glass" style={{color:'#ffb4b4'}}>{err}</div></div>;
  if (!data) return <div className="container"><div className="card glass">Загрузка…</div></div>;

  const photos = Array.isArray(data.photos) ? data.photos.map((url:string)=>({url})) : (data.photo_url? [{url:data.photo_url}] : []);

  return (
    <div className="container">
      <h2 className="h2">{data.title || `Место #${id}`}</h2>
      <div className="muted" style={{marginBottom:8}}>{data.description || '—'}</div>
      <div className="muted">{data.lat?.toFixed?.(4)}, {data.lng?.toFixed?.(4)}</div>

      <div style={{marginTop:12}}>
        <MediaGrid items={photos} />
      </div>
    </div>
  );
};
export default PlaceDetailPage;
TS

############################################
# 15) pages/AddCatchPage.tsx — форма с ISO datetime
############################################
cat > "$SRC/pages/AddCatchPage.tsx" <<'TS'
import React, { useState } from 'react';
import { addCatch } from '../api';

const AddCatchPage: React.FC = () => {
  const [form, setForm] = useState<any>({
    species:'', length:'', weight:'',
    style:'', lure:'', tackle:'', notes:'',
    photo_url:'', lat:'', lng:'', caught_at:'', privacy:'all'
  });
  const [msg, setMsg] = useState('');

  function set<K extends string>(k:K, v:any){ setForm((s:any)=> ({...s, [k]:v})); }

  async function submit(e:React.FormEvent){
    e.preventDefault(); setMsg('');
    try{
      const payload = {
        ...form,
        length: form.length? Number(form.length): undefined,
        weight: form.weight? Number(form.weight): undefined,
        lat: form.lat? Number(form.lat): undefined,
        lng: form.lng? Number(form.lng): undefined,
        caught_at: form.caught_at ? new Date(form.caught_at).toISOString() : undefined,
      };
      await addCatch(payload);
      setMsg('Улов добавлен');
    }catch(ex:any){ setMsg(ex?.message || 'Ошибка сохранения'); }
  }

  return (
    <div className="container">
      <h2 className="h2">Добавить улов</h2>
      <form className="glass card grid" onSubmit={submit}>
        <input className="input" placeholder="Вид рыбы" value={form.species} onChange={e=>set('species', e.target.value)} />
        <div className="row" style={{gap:8}}>
          <input className="input" placeholder="Длина (см)" value={form.length} onChange={e=>set('length', e.target.value)} />
          <input className="input" placeholder="Вес (кг)" value={form.weight} onChange={e=>set('weight', e.target.value)} />
        </div>
        <div className="row" style={{gap:8}}>
          <input className="input" placeholder="Стиль" value={form.style} onChange={e=>set('style', e.target.value)} />
          <input className="input" placeholder="Приманка" value={form.lure} onChange={e=>set('lure', e.target.value)} />
          <input className="input" placeholder="Снасти" value={form.tackle} onChange={e=>set('tackle', e.target.value)} />
        </div>
        <textarea className="textarea" placeholder="Заметки" value={form.notes} onChange={e=>set('notes', e.target.value)} />
        <input className="input" placeholder="URL фото" value={form.photo_url} onChange={e=>set('photo_url', e.target.value)} />

        <div className="row" style={{gap:8}}>
          <input className="input" placeholder="Широта" value={form.lat} onChange={e=>set('lat', e.target.value)} />
          <input className="input" placeholder="Долгота" value={form.lng} onChange={e=>set('lng', e.target.value)} />
        </div>

        <label className="muted">Дата/время по местному времени (ISO будет сформирован автоматически)</label>
        <input className="input" type="datetime-local" value={form.caught_at} onChange={e=>set('caught_at', e.target.value)} />

        <select className="select" value={form.privacy} onChange={e=>set('privacy', e.target.value)}>
          <option value="all">Все</option>
          <option value="friends">Друзья</option>
          <option value="private">Лично</option>
        </select>

        <button className="btn primary" type="submit">Сохранить</button>
        {msg && <div className="muted">{msg}</div>}
      </form>
    </div>
  );
};
export default AddCatchPage;
TS

############################################
# 16) pages/AddPlacePage.tsx — форма места
############################################
cat > "$SRC/pages/AddPlacePage.tsx" <<'TS'
import React, { useState } from 'react';
import { addPlace } from '../api';

const AddPlacePage: React.FC = () => {
  const [form, setForm] = useState<any>({ title:'', description:'', lat:'', lng:'', photos:'' });
  const [msg, setMsg] = useState('');

  function set<K extends string>(k:K, v:any){ setForm((s:any)=> ({...s, [k]:v})); }

  async function submit(e:React.FormEvent){
    e.preventDefault(); setMsg('');
    try{
      const payload = {
        title: form.title,
        description: form.description || undefined,
        lat: Number(form.lat),
        lng: Number(form.lng),
        photos: form.photos ? form.photos.split(',').map((s:string)=>s.trim()).filter(Boolean) : undefined,
      };
      await addPlace(payload);
      setMsg('Место добавлено');
    }catch(ex:any){ setMsg(ex?.message || 'Ошибка сохранения'); }
  }

  return (
    <div className="container">
      <h2 className="h2">Добавить место</h2>
      <form className="glass card grid" onSubmit={submit}>
        <input className="input" placeholder="Название" value={form.title} onChange={e=>set('title', e.target.value)} required />
        <textarea className="textarea" placeholder="Описание" value={form.description} onChange={e=>set('description', e.target.value)} />
        <div className="row" style={{gap:8}}>
          <input className="input" placeholder="Широта" value={form.lat} onChange={e=>set('lat', e.target.value)} required />
          <input className="input" placeholder="Долгота" value={form.lng} onChange={e=>set('lng', e.target.value)} required />
        </div>
        <input className="input" placeholder="URL фото через запятую" value={form.photos} onChange={e=>set('photos', e.target.value)} />
        <button className="btn primary" type="submit">Сохранить</button>
        {msg && <div className="muted">{msg}</div>}
      </form>
    </div>
  );
};
export default AddPlacePage;
TS

############################################
# 17) pages/NotificationsPage.tsx
############################################
cat > "$SRC/pages/NotificationsPage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { notifications } from '../api';

const NotificationsPage: React.FC = () => {
  const [list, setList] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    notifications()
      .then(r => setList(Array.isArray(r)? r: []))
      .catch(e => setErr(e.message || 'Маршрут уведомлений не найден'));
  },[]);

  return (
    <div className="container">
      <h2 className="h2">Уведомления</h2>
      {err && <div className="card glass" style={{color:'#ffb4b4'}}>{err}</div>}
      {!err && list.length===0 && <div className="card glass">Пока пусто</div>}
      <div className="grid">
        {list.map((n,i)=>(
          <div key={i} className="card glass">
            <div style={{fontWeight:600}}>{n.title || 'Уведомление'}</div>
            <div className="muted">{n.created_at ? new Date(n.created_at).toLocaleString(): ''}</div>
            <div style={{marginTop:6}}>{n.text || n.message || ''}</div>
          </div>
        ))}
      </div>
    </div>
  );
};
export default NotificationsPage;
TS

############################################
# 18) pages/ProfilePage.tsx (исправлено)
############################################
cat > "$SRC/pages/ProfilePage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import config from '../config';
import { profileMe, isAuthed, logout } from '../api';

const ProfilePage: React.FC = () => {
  const [me, setMe] = useState<any>(null);
  const [err, setErr] = useState<string>('');

  useEffect(() => {
    if (!isAuthed()) {
      setErr('Требуется вход в систему.');
      return;
    }
    profileMe()
      .then(setMe)
      .catch((e) => setErr(e.message || 'Не удалось загрузить профиль'));
  }, []);

  const avatar = me?.photo_url || config?.images?.defaultAvatar || '/assets/default-avatar.png';

  return (
    <div className="container">
      <div className="glass card" style={{display:'flex', gap:12, alignItems:'center'}}>
        <img src={avatar} alt="avatar" style={{width:64, height:64, borderRadius:'50%', objectFit:'cover'}} />
        <div style={{flex:1}}>
          <div style={{fontWeight:600}}>{me?.name || '—'}</div>
          <div className="muted">{me?.email || ''}</div>
        </div>
        {isAuthed() && (
          <button className="btn" onClick={()=>{ logout(); location.href='/login'; }}>Выйти</button>
        )}
      </div>
      {err && <div className="card glass" style={{color:'#ffb4b4', marginTop:10}}>{err}</div>}
    </div>
  );
};

export default ProfilePage;
TS

############################################
# 19) pages/WeatherPage.tsx (исправлено)
############################################
cat > "$SRC/pages/WeatherPage.tsx" <<'TS'
import React from 'react';
import { getWeatherFavs } from '../api';

const WeatherPage: React.FC = () => {
  const favs = getWeatherFavs();
  const list = Array.isArray(favs) ? favs : [];

  return (
    <div className="container">
      <h2 className="h2">Погода</h2>
      {list.length === 0 ? (
        <div className="muted glass card">Пока ни одной избранной точки. Нажмите по карте, чтобы добавить.</div>
      ) : (
        <ul className="grid" style={{listStyle:'none', padding:0}}>
          {list.map((p, idx) => (
            <li key={idx} className="card glass">
              <div style={{fontWeight:600}}>{p.title || `Точка (${p.lat.toFixed(4)}, ${p.lng.toFixed(4)})`}</div>
              <div className="muted">температура: — / ветер: — (добавим, когда появится серверный маршрут)</div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};

export default WeatherPage;
TS

############################################
# 20) pages/LoginPage.tsx / RegisterPage.tsx
############################################
cat > "$SRC/pages/LoginPage.tsx" <<'TS'
import React, { useState } from 'react';
import { login } from '../api';
import { useNavigate, Link } from 'react-router-dom';

const LoginPage: React.FC = () => {
  const nav = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPwd] = useState('');
  const [err, setErr] = useState('');

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr('');
    try {
      await login(email, password);
      nav('/profile', { replace: true });
    } catch (ex:any) {
      setErr(ex?.message || 'Ошибка входа');
    }
  }

  return (
    <div className="container">
      <form className="glass card" onSubmit={onSubmit} style={{display:'grid', gap:10, maxWidth:420, margin:'0 auto'}}>
        <h2>Вход</h2>
        <label>Email</label>
        <input className="input" value={email} onChange={e=>setEmail(e.target.value)} required />
        <label>Пароль</label>
        <input className="input" type="password" value={password} onChange={e=>setPwd(e.target.value)} required />
        <button className="btn primary" type="submit">Войти</button>
        {err && <div style={{color:'#ffb4b4'}}>{err}</div>}
        <div className="muted">Нет аккаунта? <Link to="/register">Регистрация</Link></div>
      </form>
    </div>
  );
};

export default LoginPage;
TS

cat > "$SRC/pages/RegisterPage.tsx" <<'TS'
import React, { useState } from 'react';
import { register } from '../api';
import { useNavigate, Link } from 'react-router-dom';

const RegisterPage: React.FC = () => {
  const nav = useNavigate();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPwd] = useState('');
  const [err, setErr] = useState('');

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr('');
    try {
      await register(name, email, password);
      nav('/profile', { replace: true });
    } catch (ex:any) {
      setErr(ex?.message || 'Ошибка регистрации');
    }
  }

  return (
    <div className="container">
      <form className="glass card" onSubmit={onSubmit} style={{display:'grid', gap:10, maxWidth:420, margin:'0 auto'}}>
        <h2>Регистрация</h2>
        <label>Имя</label>
        <input className="input" value={name} onChange={e=>setName(e.target.value)} required />
        <label>Email</label>
        <input className="input" value={email} onChange={e=>setEmail(e.target.value)} required />
        <label>Пароль</label>
        <input className="input" type="password" value={password} onChange={e=>setPwd(e.target.value)} required />
        <button className="btn primary" type="submit">Создать аккаунт</button>
        {err && <div style={{color:'#ffb4b4'}}>{err}</div>}
        <div className="muted">Уже есть аккаунт? <Link to="/login">Вход</Link></div>
      </form>
    </div>
  );
};

export default RegisterPage;
TS

############################################
# 21) AppRoot.tsx — роутинг + ProtectedRoute
############################################
cat > "$SRC/AppRoot.tsx" <<'TS'
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';

import Header from './components/Header';
import BottomNav from './components/BottomNav';

import FeedScreen from './pages/FeedScreen';
import MapScreen from './pages/MapScreen';
import AddCatchPage from './pages/AddCatchPage';
import AddPlacePage from './pages/AddPlacePage';
import NotificationsPage from './pages/NotificationsPage';
import ProfilePage from './pages/ProfilePage';
import WeatherPage from './pages/WeatherPage';
import CatchDetailPage from './pages/CatchDetailPage';
import PlaceDetailPage from './pages/PlaceDetailPage';

import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import { isAuthed } from './api';

const ProtectedRoute: React.FC<{ children: React.ReactElement }> = ({ children }) => {
  if (!isAuthed()) return <Navigate to="/login" replace />;
  return children;
};

const AppRoot: React.FC = () => {
  return (
    <BrowserRouter>
      <div className="app-shell">
        <Header />
        <main className="app-main">
          <Routes>
            <Route path="/" element={<Navigate to="/feed" replace />} />
            <Route path="/feed" element={<FeedScreen />} />
            <Route path="/map" element={<MapScreen />} />
            <Route path="/catch/:id" element={<CatchDetailPage />} />
            <Route path="/place/:id" element={<PlaceDetailPage />} />
            <Route path="/weather" element={<WeatherPage />} />
            <Route path="/alerts" element={<NotificationsPage />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />

            <Route path="/add/catch" element={<ProtectedRoute><AddCatchPage /></ProtectedRoute>} />
            <Route path="/add/place" element={<ProtectedRoute><AddPlacePage /></ProtectedRoute>} />
            <Route path="/profile" element={<ProtectedRoute><ProfilePage /></ProtectedRoute>} />

            <Route path="*" element={<Navigate to="/feed" replace />} />
          </Routes>
        </main>
        <BottomNav />
      </div>
      <style>{`
        .app-shell { min-height: 100svh; display: grid; grid-template-rows: auto 1fr auto; }
        .app-main { min-height: 0; }
      `}</style>
    </BrowserRouter>
  );
};

export default AppRoot;
TS

############################################
# 22) main.tsx — подключение шрифтов и стилей
############################################
cat > "$SRC/main.tsx" <<'TS'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './AppRoot';
import './styles/app.css';

// Подключаем Material Symbols (аксисы — по алфавиту: FILL, GRAD, opsz, wght)
const fonts = document.createElement('link');
fonts.rel = 'stylesheet';
fonts.href = 'https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:FILL@0..1,GRAD@-25..200,opsz@20..48,wght@100..700';
document.head.appendChild(fonts);

const el = document.getElementById('root');
if (el) {
  const root = createRoot(el);
  root.render(<App />);
  console.log('[boot] App mounted');
}
TS

############################################
# 23) index.html (если его нет)
############################################
if [ ! -f "$ROOT/index.html" ] && [ ! -f "$ROOT/frontend/index.html" ]; then
  cat > "$ROOT/index.html" <<'HTML'
<!doctype html>
<html lang="ru">
  <head>
    <meta charset="UTF-8" />
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1, viewport-fit=cover"
    />
    <title>FishTrack Pro</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
HTML
fi

############################################
# 24) package.json — добавим react-router-dom/leaflet если нужно
############################################
if [ -f "$ROOT/package.json" ]; then
  :
elif [ -f "$ROOT/frontend/package.json" ]; then
  :
else
  cat > "$ROOT/package.json" <<'JSON'
{
  "name": "fishtrackpro-frontend",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 5173"
  },
  "dependencies": {
    "leaflet": "^1.9.4",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.26.1"
  },
  "devDependencies": {
    "@types/react": "^18.3.7",
    "@types/react-dom": "^18.3.0",
    "typescript": "^5.6.2",
    "vite": "^7.1.4"
  }
}
JSON
fi

echo "✅ Frontend files updated."
echo "— Проверь src/ структуры, затем: npm i && npm run build"