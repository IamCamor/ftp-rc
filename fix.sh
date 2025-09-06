#!/usr/bin/env bash
set -euo pipefail

ROOT="${PWD}/frontend"
SRC="${ROOT}/src"
CMP="${SRC}/components"
PAGES="${SRC}/pages"
STY="${SRC}/styles"

need() { [[ -d "$1" ]] || { echo "❌ Не найден каталог: $1"; exit 1; }; }
need "$SRC"; need "$CMP"; need "$PAGES"; need "$STY"

############################################
# 1) config.ts — базовый конфиг и размеры UI
############################################
cat > "${SRC}/config.ts" <<'TS'
export const API_BASE = 'https://api.fishtrackpro.ru/api'; // без /v1 — добавим в api.ts
export const TILES_URL = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

export const ICONS = {
  // указываем имена иконок из Material Symbols Rounded
  header: { weather: 'weather_mix', bell: 'notifications', add: 'add_circle', profile: 'account_circle' },
  bottom: { feed: 'home', map: 'map', addCatch: 'add_photo_alternate', addPlace: 'add_location', alerts: 'notifications', profile: 'person' },
  actions: { like: 'favorite', comment: 'mode_comment', share: 'share', open: 'open_in_new', weatherSave: 'cloud_download' },
};

export const UI_DIMENSIONS = { header: 56, bottomNav: 64 };
TS

#############################
# 2) styles/app.css — Material Icons + glass
#############################
cat > "${STY}/app.css" <<'CSS'
@import url('https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,300..700,0..1,-50..200');

.material-symbols-rounded {
  font-family: 'Material Symbols Rounded';
  font-weight: normal;
  font-style: normal;
  font-size: 24px; /* Adjust as needed */
  line-height: 1;
  letter-spacing: normal;
  text-transform: none;
  display: inline-block;
  white-space: nowrap;
  direction: ltr;
  -webkit-font-feature-settings: 'liga';
  -webkit-font-smoothing: antialiased;
  /* вариативные оси (важно: порядок осей соответствует CSS @import выше) */
  font-variation-settings: 'opsz' 24, 'wght' 400, 'FILL' 0, 'GRAD' 0;
}

/* простая сетка и стек карт */
:root {
  --bg: #0b1220;
  --glass-bg: rgba(255,255,255,0.06);
  --glass-border: rgba(255,255,255,0.12);
  --txt: #eaf0ff;
  --muted: #a7b0c6;
  --accent: #7cc1ff;
}

html, body, #root { height: 100%; }
body { margin: 0; background: radial-gradient(1200px 800px at 20% -10%, rgba(124,193,255,0.10), transparent 60%), var(--bg); color: var(--txt); font-family: Inter, system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, 'Helvetica Neue', Arial, 'Noto Sans', 'Apple Color Emoji','Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji'; }

a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }

.glass { background: var(--glass-bg); border: 1px solid var(--glass-border); backdrop-filter: blur(10px); border-radius: 16px; }
.glass-light { background: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.14); backdrop-filter: blur(8px); border-radius: 10px; }
.card { padding: 12px; border-radius: 16px; border: 1px solid rgba(255,255,255,0.08); background: rgba(255,255,255,0.03); }

.header { position: sticky; top: 0; z-index: 50; height: 56px; display: grid; grid-template-columns: 1fr auto auto auto; align-items: center; gap: 8px; padding: 8px 12px; }
.header .brand { font-weight: 600; letter-spacing: 0.2px; }

.bottom-nav { position: fixed; left: 0; right: 0; bottom: 0; height: 64px; display: grid; grid-template-columns: repeat(5, 1fr); align-items: center; gap: 4px; padding: 8px; z-index: 50; }
.bottom-nav a { color: var(--txt); opacity: 0.8; text-align: center; font-size: 12px; }
.bottom-nav a.active { opacity: 1; color: white; }

.btn { padding: 10px 14px; border-radius: 12px; border: 1px solid rgba(255,255,255,0.18); background: rgba(255,255,255,0.08); color: var(--txt); cursor: pointer; }
.btn:disabled { opacity: 0.5; cursor: default; }

.leaflet-container { background: #0a0f1b; }
CSS

##################################
# 3) components/Icon.tsx — универсальная иконка
##################################
cat > "${CMP}/Icon.tsx" <<'TSX'
import React from 'react';

type Props = { name: string; size?: number; fill?: 0|1; weight?: number; grad?: number; className?: string; style?: React.CSSProperties };

export default function Icon({ name, size=24, fill=0, weight=400, grad=0, className='', style }: Props) {
  const styles: React.CSSProperties = {
    fontVariationSettings: `'opsz' ${size}, 'wght' ${weight}, 'FILL' ${fill}, 'GRAD' ${grad}`,
    fontSize: size,
    ...style,
  };
  return <span className={`material-symbols-rounded ${className}`} style={styles} aria-hidden="true">{name}</span>;
}
TSX

##################################
# 4) components/Header.tsx — шапка с кнопками (погода/уведомления/профиль)
##################################
cat > "${CMP}/Header.tsx" <<'TSX'
import React from 'react';
import Icon from './Icon';
import { ICONS } from '../config';

export default function Header() {
  return (
    <div className="header glass">
      <div className="brand"><a href="/feed">FishTrack<span style={{opacity:.6}}>Pro</span></a></div>
      <a href="/weather" title="Погода" aria-label="Погода"><Icon name={ICONS.header.weather} /></a>
      <a href="/alerts" title="Уведомления" aria-label="Уведомления"><Icon name={ICONS.header.bell} /></a>
      <a href="/profile" title="Профиль" aria-label="Профиль"><Icon name={ICONS.header.profile} /></a>
    </div>
  );
}
TSX

##################################
# 5) components/BottomNav.tsx — нижнее меню (без #)
##################################
cat > "${CMP}/BottomNav.tsx" <<'TSX'
import React from 'react';
import Icon from './Icon';
import { ICONS } from '../config';

const items = [
  { href:'/feed', label:'Лента', icon: ICONS.bottom.feed },
  { href:'/map', label:'Карта', icon: ICONS.bottom.map },
  { href:'/add-catch', label:'Улов', icon: ICONS.bottom.addCatch },
  { href:'/add-place', label:'Место', icon: ICONS.bottom.addPlace },
  { href:'/alerts', label:'Алерты', icon: ICONS.bottom.alerts },
];

export default function BottomNav(){
  const path = typeof window !== 'undefined' ? window.location.pathname : '';
  return (
    <nav className="bottom-nav glass">
      {items.map(it=>{
        const active = path===it.href;
        return (
          <a key={it.href} href={it.href} className={active?'active':''} aria-label={it.label}>
            <div><Icon name={it.icon} /></div>
            <div style={{fontSize:10, marginTop:2}}>{it.label}</div>
          </a>
        );
      })}
    </nav>
  );
}
TSX

##################################
# 6) api.ts — Единая обёртка, default export api + именованный points
##################################
cat > "${SRC}/api.ts" <<'TS'
import { API_BASE } from './config';

type Method = 'GET'|'POST'|'PUT'|'PATCH'|'DELETE';
type Q = Record<string, string|number|boolean|undefined|null>;

async function http<T>(path:string, {method='GET', body, auth=false, query}:{method?:Method; body?:any; auth?:boolean; query?:Q} = {}):Promise<T>{
  const url = new URL(API_BASE + path);
  if (query) Object.entries(query).forEach(([k,v])=>{
    if (v!==undefined && v!==null && v!=='') url.searchParams.set(k,String(v));
  });
  const opts: RequestInit = {
    method,
    mode:'cors',
    credentials: auth ? 'include' : 'omit',
    headers: body instanceof FormData ? {'Accept':'application/json'} : {'Content-Type':'application/json','Accept':'application/json'},
    body: body ? (body instanceof FormData ? body : JSON.stringify(body)) : undefined,
  };
  const res = await fetch(url.toString(), opts);
  if (!res.ok) {
    let msg = '';
    try { msg = JSON.stringify(await res.clone().json()); } catch { msg = await res.text(); }
    throw new Error(`${res.status} ${res.statusText} :: ${msg.slice(0,400)}`);
  }
  if (res.status===204) return {} as T;
  const ct = res.headers.get('content-type')||'';
  return ct.includes('application/json') ? res.json() : (await res.text() as unknown as T);
}

export const api = {
  // FEED / MAP (всегда через /v1)
  feed: (p:{limit?:number; offset?:number; sort?:'new'|'top'; fish?:string; near?:string}={}) => http('/v1/feed',{query:p}),
  points: (p:{limit?:number; bbox?:string; filter?:string}={}) => http('/v1/map/points',{query:p}),

  // DETAIL
  catchById: (id:number|string)=> http(`/v1/catch/${id}`),

  // WEATHER
  weather: (p:{lat:number; lng:number; dt?:number})=> http('/v1/weather',{query:p}),

  // MUTATIONS
  addCatch: (payload:any)=> http('/v1/catches',{method:'POST', body:payload}),
  addPlace: (payload:any)=> http('/v1/points',{method:'POST', body:payload}),

  // PROFILE / ALERTS
  me: ()=> http('/v1/profile/me', {auth:true}),
  notifications: ()=> http('/v1/notifications', {auth:true}),

  // SOCIAL
  likeToggle: (id:number|string)=> http(`/v1/catch/${id}/like`, {method:'POST', auth:true}),
  addComment: (id:number|string, payload:{text:string})=> http(`/v1/catch/${id}/comments`, {method:'POST', body:payload, auth:true}),
  followToggle: (userId:number|string)=> http(`/v1/follow/${userId}`, {method:'POST', auth:true}),
};

export default api;

// совместимость для старых импортов { points }
export const points = (p:{limit?:number; bbox?:string; filter?:string}={}) => api.points(p);

// локальные «избранные локации погоды»
const WEATHER_KEY = 'weather_favs';
export type WeatherFav = { id: string; name: string; lat: number; lng: number };
export const getWeatherFavs = ():WeatherFav[] => {
  try { const v = localStorage.getItem(WEATHER_KEY); const arr = v? JSON.parse(v): []; return Array.isArray(arr)?arr:[]; } catch { return []; }
};
export const saveWeatherFav = (fav:WeatherFav) => {
  const list = getWeatherFavs();
  const i = list.findIndex(x=>x.id===fav.id);
  if (i>=0) list[i]=fav; else list.push(fav);
  localStorage.setItem(WEATHER_KEY, JSON.stringify(list));
  return list;
};
TS

##################################
# 7) pages/MapScreen.tsx — карта + добавление точки + «в погоду»
##################################
cat > "${PAGES}/MapScreen.tsx" <<'TSX'
import React, { useEffect, useRef, useState } from 'react';
import api, { getWeatherFavs, saveWeatherFav } from '../api';
import { TILES_URL, UI_DIMENSIONS } from '../config';
import Icon from '../components/Icon';
import 'leaflet/dist/leaflet.css';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from 'react-leaflet';
import L from 'leaflet';

type Point = {
  id: number;
  type?: string;
  lat: number;
  lng: number;
  title?: string;
  photos?: string[];
  catch_id?: number;
};

const defaultCenter: [number, number] = [55.751244, 37.618423];
const pinIcon = new L.Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25,41],
  iconAnchor: [12,41],
});

function BoundsListener({ onBounds, onClick }: {onBounds:(b:L.LatLngBounds)=>void; onClick:(lat:number,lng:number)=>void}) {
  useMapEvents({
    moveend: (e)=> onBounds(e.target.getBounds()),
    zoomend: (e)=> onBounds(e.target.getBounds()),
    load: (e)=> onBounds(e.target.getBounds()),
    click: (e)=> onClick(e.latlng.lat, e.latlng.lng),
  });
  return null;
}

export default function MapScreen() {
  const [data,setData] = useState<Point[]>([]);
  const [error,setError] = useState('');
  const [draft,setDraft] = useState<{lat:number;lng:number}|null>(null);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(()=>{
    const h = window.innerHeight - UI_DIMENSIONS.header - UI_DIMENSIONS.bottomNav;
    if (ref.current) ref.current.style.height = `${Math.max(h, 320)}px`;
  },[]);

  const load = async(b?:L.LatLngBounds)=>{
    try{
      setError('');
      const bbox = b ? `${b.getWest().toFixed(2)},${b.getSouth().toFixed(2)},${b.getEast().toFixed(2)},${b.getNorth().toFixed(2)}` : undefined;
      const raw:any = await api.points({limit:500, bbox});
      const list = Array.isArray(raw?.items) ? raw.items
                 : Array.isArray(raw?.data) ? raw.data
                 : Array.isArray(raw) ? raw : [];
      const normalized: Point[] = list.map((p:any)=>({
        id: Number(p.id ?? p.point_id ?? Math.random()*1e9),
        type: p.type ?? p.category ?? 'spot',
        lat: Number(p.lat ?? p.latitude),
        lng: Number(p.lng ?? p.longitude),
        title: p.title ?? p.name ?? '',
        photos: Array.isArray(p.photos) ? p.photos : (p.photo_url ? [p.photo_url] : []),
        catch_id: p.catch_id ? Number(p.catch_id) : undefined,
      })).filter(p=>!Number.isNaN(p.lat)&&!Number.isNaN(p.lng));
      setData(normalized);
    }catch(e:any){
      setError(e?.message || 'Ошибка загрузки точек');
      setData([]);
    }
  };

  const openEntity = (p:Point)=> { window.location.href = p.catch_id ? `/catch/${p.catch_id}` : `/place/${p.id}`; };

  const addToWeather = (lat:number,lng:number,name='Точка')=>{
    const id = `point-${lat.toFixed(4)}-${lng.toFixed(4)}`;
    saveWeatherFav({ id, name, lat, lng });
    alert('Локация сохранена на странице погоды');
  };

  const savePlace = async ()=>{
    if(!draft) return;
    try{
      await api.addPlace({ lat: draft.lat, lng: draft.lng, title:'Моё место' });
      setDraft(null);
      await load();
      addToWeather(draft.lat,draft.lng,'Моё место');
    }catch(e:any){
      alert('Не удалось сохранить место: '+(e?.message||''));
    }
  };

  return (
    <div className="p-3">
      <div className="glass card mb-3" style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:12}}>
        <div><strong>Карта</strong></div>
        <div style={{display:'flex',gap:8}}>
          <a className="btn" href="/add-place"><Icon name="add_location" />&nbsp;Добавить точку</a>
          <a className="btn" href="/add-catch"><Icon name="add_photo_alternate" />&nbsp;Добавить улов</a>
        </div>
      </div>

      <div ref={ref} className="card" style={{overflow:'hidden'}}>
        <MapContainer center={defaultCenter} zoom={10} style={{width:'100%',height:'100%'}}>
          <TileLayer url={TILES_URL} attribution="&copy; OpenStreetMap contributors"/>
          <BoundsListener
            onBounds={(b)=>load(b)}
            onClick={(lat,lng)=> setDraft({lat,lng}) }
          />

          {data.map(p=>(
            <Marker key={`${p.id}-${p.lat}-${p.lng}`} position={[p.lat,p.lng]} icon={pinIcon}>
              <Popup>
                <div style={{maxWidth:240}}>
                  <div className="font-medium mb-2">{p.title || 'Точка'}</div>
                  {p.photos && p.photos.length ? (
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
                      {p.photos.slice(0,4).map((src,idx)=>(
                        <img key={idx} src={src} alt="" style={{width:'100%',height:'80px',objectFit:'cover',borderRadius:8,cursor:'pointer'}} onClick={()=>openEntity(p)} />
                      ))}
                    </div>
                  ) : <div className="opacity-70 text-sm mb-2">Фото не прикреплены</div>}
                  <div className="mt-2" style={{display:'flex',gap:8}}>
                    <button className="btn" onClick={()=>openEntity(p)}><Icon name="open_in_new" />&nbsp;Открыть</button>
                    <button className="btn" onClick={()=>addToWeather(p.lat,p.lng,p.title||'Точка')}><Icon name="cloud_download" />&nbsp;В погоду</button>
                  </div>
                </div>
              </Popup>
            </Marker>
          ))}

          {draft && (
            <Marker position={[draft.lat,draft.lng]} icon={pinIcon}>
              <Popup>
                <div style={{maxWidth:220}}>
                  Новая точка<br/>
                  {draft.lat.toFixed(5)}, {draft.lng.toFixed(5)}
                  <div className="mt-2" style={{display:'flex',gap:8}}>
                    <button className="btn" onClick={savePlace}><Icon name="save" />&nbsp;Сохранить</button>
                    <button className="btn" onClick={()=>setDraft(null)}><Icon name="close" />&nbsp;Отмена</button>
                  </div>
                </div>
              </Popup>
            </Marker>
          )}
        </MapContainer>
      </div>

      {!!error && <div className="mt-3" style={{color:'#ff9b9b'}}>Ошибка карты: {error}</div>}

      <div className="glass card mt-3" style={{display:'flex',justifyContent:'space-between'}}>
        <div>Избранные локации погоды: {getWeatherFavs().length || 0}</div>
        <a className="btn" href="/weather"><Icon name="weather_mix" />&nbsp;Открыть погоду</a>
      </div>
    </div>
  );
}
TSX

##################################
# 8) pages/FeedScreen.tsx — лента на api.feed
##################################
cat > "${PAGES}/FeedScreen.tsx" <<'TSX'
import React, { useEffect, useState } from 'react';
import api from '../api';
import Icon from '../components/Icon';

type FeedItem = {
  id:number;
  user_name?:string;
  media_url?:string;
  caption?:string;
  likes_count?:number;
  comments_count?:number;
  created_at?:string;
};

export default function FeedScreen(){
  const [data,setData] = useState<FeedItem[]>([]);
  const [error,setError] = useState('');

  useEffect(()=>{
    (async()=>{
      try{
        setError('');
        const res:any = await api.feed({limit:10, offset:0});
        const list = Array.isArray(res?.items) ? res.items
                   : Array.isArray(res?.data) ? res.data
                   : Array.isArray(res) ? res : [];
        setData(list);
      }catch(e:any){
        setError(e?.message||'Ошибка ленты');
      }
    })();
  },[]);

  return (
    <div className="p-3" style={{paddingBottom:80}}>
      <div className="glass card mb-3" style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
        <strong>Лента</strong>
        <a className="btn" href="/add-catch"><Icon name="add_photo_alternate" />&nbsp;Добавить улов</a>
      </div>
      {!!error && <div className="card" style={{color:'#ff9b9b'}}>{error}</div>}
      {data.map((it)=>(
        <div key={it.id} className="card glass mb-3">
          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:8}}>
            <div style={{width:32,height:32,borderRadius:'50%',background:'rgba(255,255,255,0.1)'}} />
            <div style={{fontWeight:600}}>{it.user_name||'Рыбак'}</div>
            <div style={{marginLeft:'auto', opacity:.7, fontSize:12}}>{new Date(it.created_at||Date.now()).toLocaleString()}</div>
          </div>
          {it.media_url && <img src={it.media_url} alt="" style={{width:'100%',borderRadius:12,objectFit:'cover',maxHeight:420}} />}
          {it.caption && <div style={{marginTop:8}}>{it.caption}</div>}
          <div style={{display:'flex',gap:16,marginTop:8}}>
            <button className="btn"><Icon name="favorite" /> {it.likes_count ?? 0}</button>
            <button className="btn"><Icon name="mode_comment" /> {it.comments_count ?? 0}</button>
            <button className="btn"><Icon name="share" /> Поделиться</button>
          </div>
          <div style={{marginTop:8}}>
            <a href={`/catch/${it.id}`}><Icon name="open_in_new" /> Открыть</a>
          </div>
        </div>
      ))}
    </div>
  );
}
TSX

##################################
# 9) pages/NotificationsPage.tsx — использует /v1/notifications
##################################
cat > "${PAGES}/NotificationsPage.tsx" <<'TSX'
import React, { useEffect, useState } from 'react';
import api from '../api';

type N = { id:number|string; type:string; text:string; created_at?:string };

export default function NotificationsPage(){
  const [list,setList] = useState<N[]>([]);
  const [error,setError] = useState('');

  useEffect(()=>{
    (async()=>{
      try{
        setError('');
        const res:any = await api.notifications();
        const arr = Array.isArray(res?.items)?res.items : Array.isArray(res?.data)?res.data : Array.isArray(res)?res : [];
        setList(arr);
      }catch(e:any){
        setError(e?.message||'Не удалось загрузить уведомления');
      }
    })();
  },[]);

  return (
    <div className="p-3" style={{paddingBottom:80}}>
      <div className="glass card mb-3"><strong>Уведомления</strong></div>
      {!!error && <div className="card" style={{color:'#ff9b9b'}}>{error}</div>}
      {list.length===0 && !error && <div className="card">Уведомлений пока нет</div>}
      {list.map(n=>(
        <div key={String(n.id)} className="card glass mb-2">
          <div style={{fontWeight:600, marginBottom:4}}>{n.type}</div>
          <div>{n.text}</div>
          <div style={{opacity:.6, fontSize:12, marginTop:6}}>{n.created_at? new Date(n.created_at).toLocaleString() : ''}</div>
        </div>
      ))}
    </div>
  );
}
TSX

##################################
# 10) pages/ProfilePage.tsx — /v1/profile/me
##################################
cat > "${PAGES}/ProfilePage.tsx" <<'TSX'
import React, { useEffect, useState } from 'react';
import api from '../api';

type Me = { id:number; name:string; points?:number; avatar_url?:string };

export default function ProfilePage(){
  const [me,setMe] = useState<Me|null>(null);
  const [error,setError] = useState('');

  useEffect(()=>{
    (async()=>{
      try{
        setError('');
        const res:any = await api.me();
        setMe(res);
      }catch(e:any){
        setError(e?.message||'Не удалось загрузить профиль');
      }
    })();
  },[]);

  return (
    <div className="p-3" style={{paddingBottom:80}}>
      <div className="glass card mb-3"><strong>Профиль</strong></div>
      {!!error && <div className="card" style={{color:'#ff9b9b'}}>{error}</div>}
      {!me && !error && <div className="card">Не авторизован</div>}
      {me && (
        <div className="glass card">
          <div style={{display:'flex',gap:12,alignItems:'center'}}>
            <div style={{width:64,height:64,borderRadius:'50%',background:'rgba(255,255,255,0.1)',overflow:'hidden'}}>
              {me.avatar_url && <img src={me.avatar_url} alt="" style={{width:'100%',height:'100%',objectFit:'cover'}}/>}
            </div>
            <div>
              <div style={{fontWeight:700,fontSize:18}}>{me.name}</div>
              <div style={{opacity:.7}}>Бонусы: {me.points ?? 0}</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
TSX

##################################
# 11) App.tsx — маршруты без #, стек страниц
##################################
cat > "${SRC}/App.tsx" <<'TSX'
import React from 'react';
import Header from './components/Header';
import BottomNav from './components/BottomNav';
import FeedScreen from './pages/FeedScreen';
import MapScreen from './pages/MapScreen';
import NotificationsPage from './pages/NotificationsPage';
import ProfilePage from './pages/ProfilePage';
import './styles/app.css';

function RouterSwitch(){
  const path = typeof window !== 'undefined' ? window.location.pathname : '/feed';

  if (path === '/' || path === '/feed') return <FeedScreen />;
  if (path.startsWith('/map')) return <MapScreen />;
  if (path.startsWith('/alerts')) return <NotificationsPage />;
  if (path.startsWith('/profile')) return <ProfilePage />;

  // простые-заглушки — чтобы сборка не падала
  if (path.startsWith('/add-catch')) return <div className="p-3"><div className="card">Форма добавления улова (в разработке)</div></div>;
  if (path.startsWith('/add-place')) return <div className="p-3"><div className="card">Форма добавления места (в разработке)</div></div>;
  if (path.startsWith('/weather')) return <div className="p-3"><div className="card">Погода (в разработке)</div></div>;
  if (path.startsWith('/catch/')) return <div className="p-3"><div className="card">Карточка улова (в разработке)</div></div>;
  if (path.startsWith('/place/')) return <div className="p-3"><div className="card">Карточка места (в разработке)</div></div>;

  return <div className="p-3"><div className="card">Страница не найдена</div></div>;
}

export default function App(){
  return (
    <div>
      <Header />
      <RouterSwitch />
      <BottomNav />
    </div>
  );
}
TSX

##################################
# 12) main.tsx — монтирование
##################################
cat > "${SRC}/main.tsx" <<'TSX'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';

const rootEl = document.getElementById('root');
if (rootEl) {
  createRoot(rootEl).render(<App />);
}
TSX

echo "✅ Файлы обновлены. Теперь:"
echo "1) cd frontend"
echo "2) npm i"
echo "3) npm run build"
echo
echo "Если бэкенд отдаёт API под /api/v1/* — всё ок. Иначе поправь API_BASE в src/config.ts."