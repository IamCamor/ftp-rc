#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
SRC="$ROOT/src"
[ -d "$ROOT/frontend/src" ] && SRC="$ROOT/frontend/src"

mkdir -p "$SRC/components" "$SRC/pages" "$SRC/utils" "$SRC/assets"

############################
# 1) config.ts — флаг требовать авторизацию для сохранения точки
############################
if [ -f "$SRC/config.ts" ]; then
  # добавим поле, если его ещё нет
  if ! grep -q "requireAuthForWeatherSave" "$SRC/config.ts"; then
    tmp="$(mktemp)"
    awk '
      /auth:\s*{/ && !done {
        print;
        print "    // Требовать вход для сохранения точки погоды";
        print "    requireAuthForWeatherSave: true,";
        done=1; next
      }1
    ' "$SRC/config.ts" > "$tmp"
    mv "$tmp" "$SRC/config.ts"
  fi
else
  cat > "$SRC/config.ts" <<'TS'
export type Providers = { google:boolean; vk:boolean; yandex:boolean; apple:boolean; };
const config = {
  apiBase: 'https://api.fishtrackpro.ru/api/v1',
  authBase: 'https://api.fishtrackpro.ru',
  siteBase: 'https://www.fishtrackpro.ru',
  images: {
    logoUrl: '/assets/logo.svg',
    defaultAvatar: '/assets/default-avatar.png',
    backgroundPattern: '/assets/bg-pattern.png',
  },
  icons: { login:'login', image:'image', save:'save', google:'google', vk:'groups', yandex:'language', apple:'apple' },
  banners: { feedEvery: 5 },
  auth: {
    enabled: true,
    providers: { google:true, vk:true, yandex:true, apple:true } as Providers,
    // Важно: именно /auth/* под authBase
    routes: {
      login: '/auth/login',
      register: '/auth/register',
      oauthRedirect: (p: keyof Providers) => `/auth/${p}/redirect`,
    },
    links: {
      privacy: 'https://www.fishtrackpro.ru/docs/privacy',
      offer:   'https://www.fishtrackpro.ru/docs/offer',
      terms:   'https://www.fishtrackpro.ru/docs/terms',
    },
    username: { min:3, max:24, pattern: /^[a-zA-Z0-9._-]+$/ as unknown as RegExp },
    requireAuthForWeatherSave: true,
  }
};
export default config;
TS
fi

############################
# 2) utils/toast.ts — минимальные тосты (если уже есть — перезапишем безопасно)
############################
cat > "$SRC/components/Toast.tsx" <<'TS'
import React from 'react';
let subs: ((msg:string)=>void)[] = [];
export function pushToast(msg:string){ subs.forEach(fn=>fn(msg)); }

const ToastHost: React.FC = () => {
  const [queue,setQueue] = React.useState<string[]>([]);
  React.useEffect(()=> {
    const fn = (m:string)=> setQueue(q=>[...q,m].slice(-3));
    subs.push(fn);
    return ()=> { subs = subs.filter(s=>s!==fn); };
  }, []);
  React.useEffect(()=> {
    if(!queue.length) return;
    const t = setTimeout(()=> setQueue(q=>q.slice(1)), 2800);
    return ()=> clearTimeout(t);
  }, [queue]);
  return (
    <div style={{position:'fixed', bottom:16, left:16, zIndex:9999, display:'grid', gap:8}}>
      {queue.map((m,i)=>(
        <div key={i} className="glass card" style={{padding:'10px 12px', backdropFilter:'blur(8px)'}}>
          {m}
        </div>
      ))}
    </div>
  );
};
export default ToastHost;
TS

############################
# 3) components/Confirm.tsx — диалог подтверждения
############################
cat > "$SRC/components/Confirm.tsx" <<'TS'
import React from 'react';

type Props = {
  open: boolean;
  title?: string;
  text?: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: ()=>void;
  onCancel: ()=>void;
};
const Confirm: React.FC<Props> = ({open, title='Подтверждение', text='Вы уверены?', confirmText='ОК', cancelText='Отмена', onConfirm, onCancel})=>{
  if(!open) return null;
  return (
    <div style={{position:'fixed', inset:0, background:'rgba(0,0,0,.35)', display:'grid', placeItems:'center', zIndex:10000}}>
      <div className="glass card" style={{minWidth:320, maxWidth:520}}>
        <div className="h3" style={{marginBottom:8}}>{title}</div>
        <div className="muted" style={{marginBottom:12}}>{text}</div>
        <div className="row" style={{justifyContent:'flex-end', gap:8}}>
          <button className="btn" onClick={onCancel}>{cancelText}</button>
          <button className="btn primary" onClick={onConfirm}>{confirmText}</button>
        </div>
      </div>
    </div>
  );
};
export default Confirm;
TS

############################
# 4) api.ts — гарантируем, что login/register идут ТОЛЬКО на authBase (/auth/*),
#    добавим isAuthed(), и экспортируем saveWeatherFav как no-auth локалку (не триггерит сеть)
############################
cat > "$SRC/api.ts" <<'TS'
import config from './config';

type HttpOptions = {
  method?: 'GET'|'POST'|'PUT'|'PATCH'|'DELETE';
  body?: any;
  auth?: boolean;
  headers?: Record<string,string>;
};

function getToken(): string | null { try { return localStorage.getItem('token'); } catch { return null; } }
export function isAuthed(){ return !!getToken(); }
export function logout(){ try { localStorage.removeItem('token'); } catch {} }

async function http<T=any>(url: string, opts: HttpOptions = {}): Promise<T> {
  const { method='GET', body, auth=true, headers={} } = opts;
  const token = getToken();
  const res = await fetch(url, {
    method,
    mode: 'cors',
    credentials: 'omit',
    headers: {
      'Accept': 'application/json',
      ...(body ? {'Content-Type': 'application/json'} : {}),
      ...(auth && token ? { 'Authorization': `Bearer ${token}` } : {}),
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  const text = await res.text().catch(()=> '');
  let data: any = null;
  try { data = text ? JSON.parse(text) : null; } catch { data = text; }

  if (!res.ok) {
    const msg = (data && (data.message || data.error)) || `${res.status} ${res.statusText}`;
    const err: any = new Error(msg);
    err.status = res.status;
    err.payload = data;
    throw err;
  }
  return (data ?? undefined) as T;
}

function unwrap<T=any>(x: any, fallback: T): T {
  if (x == null) return fallback;
  if (Array.isArray(x)) return x as T;
  if (typeof x === 'object' && Array.isArray((x as any).data)) return (x as any).data as T;
  return x as T;
}

const base = config.apiBase;
const authBase = config.authBase;

/** DATA */
export async function feed(params: {limit?: number; offset?: number} = {}) {
  const q = new URLSearchParams();
  if (params.limit) q.set('limit', String(params.limit));
  if (params.offset) q.set('offset', String(params.offset));
  const r = await http<any>(`${base}/feed${q.toString()?`?${q.toString()}`:''}`);
  return unwrap<any[]>(r, []);
}
export async function points(bbox?: string, limit:number=500) {
  const q = new URLSearchParams();
  q.set('limit', String(limit));
  if (bbox) q.set('bbox', bbox);
  const r = await http<any>(`${base}/map/points?${q.toString()}`);
  return unwrap<any[]>(r, []);
}
export async function catchById(id: string|number){ return await http<any>(`${base}/catch/${id}`); }
export async function placeById(id: string|number){ return await http<any>(`${base}/place/${id}`); }
export async function addCatchComment(id:number|string, text:string){ return await http(`${base}/catch/${id}/comments`, {method:'POST', body:{text}}); }
export async function likeCatch(id:number|string){ return await http(`${base}/catch/${id}/like`, {method:'POST'}); }
export async function notifications(){ const r = await http<any>(`${base}/notifications`); return unwrap<any[]>(r, []); }
export async function profileMe(){ return await http<any>(`${base}/profile/me`); }
export async function addCatch(payload: any){ return await http(`${base}/catch`, {method:'POST', body: payload}); }
export async function addPlace(payload: any){ return await http(`${base}/place`, {method:'POST', body: payload}); }

/** WEATHER FAVS — локальное хранилище */
export function getWeatherFavs(): Array<{lat:number; lng:number; title?:string; id?:string|number}> {
  try { const raw = localStorage.getItem('weather_favs'); const parsed = raw ? JSON.parse(raw) : []; return Array.isArray(parsed) ? parsed : []; }
  catch { return []; }
}
export function saveWeatherFav(p: {lat:number; lng:number; title?:string}) {
  const list = getWeatherFavs(); list.push(p);
  try { localStorage.setItem('weather_favs', JSON.stringify(list)); } catch {}
  return list;
}

/** AUTH — только на authBase + /auth/* (никаких /api/v1/auth/*) */
export async function login(email: string, password: string) {
  const r = await http<{token?:string; [k:string]:any}>(`${authBase}/auth/login`, {method:'POST', body:{email,password}, auth:false});
  if (r?.token) localStorage.setItem('token', r.token);
  return r;
}
export async function register(name: string, email: string, password: string, username?: string, avatarUrl?: string) {
  const payload: any = {name, email, password};
  if (username) payload.username = username;
  if (avatarUrl) payload.photo_url = avatarUrl;
  const r = await http<{token?:string; [k:string]:any}>(`${authBase}/auth/register`, {method:'POST', body:payload, auth:false});
  if (r?.token) localStorage.setItem('token', r.token);
  return r;
}
export function oauthStart(provider: 'google'|'vk'|'yandex'|'apple'){
  window.location.href = `${authBase}/auth/${provider}/redirect`;
}

/** SETTINGS helpers */
export async function settingsUpdate(patch:any){ return await http<any>(`${base}/settings`, {method:'PATCH', body:patch}); }
export async function updateUsername(username: string){ return settingsUpdate({ username }); }
export async function updateAvatar(photo_url: string){ return settingsUpdate({ photo_url }); }
TS

############################
# 5) pages/MapScreen.tsx — подтверждение + требование авторизации для сохранения точки
############################
cat > "$SRC/pages/MapScreen.tsx" <<'TS'
import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { points, saveWeatherFav, isAuthed } from '../api';
import config from '../config';
import Confirm from '../components/Confirm';
import { pushToast } from '../components/Toast';

// ленивый загрузчик Leaflet (ожидается utils/leafletLoader.ts, если нет — инлайним простой)
async function loadLeaflet() {
  const L = await import('leaflet');
  // css пусть уже подключён в index.html; если нет — карта всё равно работает, только без стилей
  return L;
}

type MapPoint = {
  id: number|string;
  lat: number; lng: number;
  type?: 'place'|'catch';
  title?: string;
  preview?: string; // url
};

const MapScreen: React.FC = () => {
  const nav = useNavigate();
  const mapRef = useRef<any>(null);
  const [pts, setPts] = useState<MapPoint[]>([]);
  const [L, setL] = useState<any>(null);

  // confirm dialog state
  const [confirmOpen, setConfirmOpen] = useState(false);
  const pendingRef = useRef<{lat:number; lng:number; title?:string} | null>(null);

  useEffect(()=> {
    (async ()=>{
      const _L = await loadLeaflet(); setL(_L);
      const data = await points(undefined, 500).catch(()=>[]);
      setPts(Array.isArray(data) ? data : []);
      // init map
      const m = _L.map('map', { center:[55.75,37.6], zoom:10 });
      _L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(m);
      mapRef.current = m;

      // отрисовка
      (Array.isArray(data)? data:[]).forEach((p:any)=>{
        const marker = _L.marker([p.lat, p.lng]).addTo(m);
        const html = `
          <div style="min-width:180px">
            <div style="font-weight:600;margin-bottom:6px">${p.title || 'Точка'}</div>
            ${p.preview ? `<img src="${p.preview}" alt="" style="width:100%;height:100px;object-fit:cover;border-radius:8px" />`: ''}
            <div style="margin-top:6px;display:flex;gap:8;justify-content:flex-end">
              <a href="/place/${p.id}" data-id="${p.id}" data-type="${p.type||'place'}">Открыть</a>
            </div>
          </div>`;
        marker.bindPopup(html);
        marker.on('popupopen', (e:any)=>{
          // перехватить клик по ссылке, чтобы уйти через router
          setTimeout(()=>{
            const el = (e as any).popup?._contentNode?.querySelector('a[data-id]');
            if(el){
              el.addEventListener('click', (ev:any)=>{
                ev.preventDefault();
                const id = el.getAttribute('data-id');
                const t = el.getAttribute('data-type');
                nav(t==='catch'? `/catch/${id}` : `/place/${id}`);
              }, { once:true });
            }
          }, 0);
        });
      });

      // клик по карте — предложить сохранить в погоду
      m.on('click', (ev:any)=>{
        const { lat, lng } = ev.latlng || {};
        if (!lat || !lng) return;
        pendingRef.current = { lat, lng, title: `Точка ${lat.toFixed(4)}, ${lng.toFixed(4)}` };
        setConfirmOpen(true);
      });
    })();
  }, [nav]);

  function onCancel(){ setConfirmOpen(false); pendingRef.current = null; }
  function onConfirm(){
    setConfirmOpen(false);
    const p = pendingRef.current; pendingRef.current = null;
    if(!p) return;
    if (config.auth.requireAuthForWeatherSave && !isAuthed()){
      if (confirm('Сохранять точки могут только авторизованные.\nПерейти к авторизации?')){
        window.location.href = '/login';
      }
      return;
    }
    saveWeatherFav(p);
    pushToast('Точка сохранена для страницы погоды');
  }

  return (
    <div className="container">
      <div className="glass card" style={{marginBottom:8}}>
        Нажмите по карте, чтобы предложить сохранить точку в “Погоду”. {config.auth.requireAuthForWeatherSave?'(Требуется вход)':''}
      </div>
      <div id="map" style={{height:'70vh', width:'100%', borderRadius:16, overflow:'hidden'}} />
      <Confirm
        open={confirmOpen}
        title="Сохранить точку?"
        text="Добавить выбранную точку на страницу погоды?"
        confirmText="Сохранить"
        cancelText="Отмена"
        onConfirm={onConfirm}
        onCancel={onCancel}
      />
    </div>
  );
};

export default MapScreen;
TS

############################
# 6) Добавим ToastHost в корень приложения (если у вас AppRoot/App — вставьте сами;
#    здесь создадим безопасный AppShell, если его нет)
############################
if [ ! -f "$SRC/AppShell.tsx" ]; then
cat > "$SRC/AppShell.tsx" <<'TS'
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import ToastHost from './components/Toast';
import MapScreen from './pages/MapScreen';
const AppShell: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/map" element={<MapScreen/>} />
        <Route path="*" element={<Navigate to="/map" replace />} />
      </Routes>
      <ToastHost/>
    </BrowserRouter>
  );
};
export default AppShell;
TS
fi

############################
# 7) Если main.tsx отсутствует — создадим минимальный
############################
if [ ! -f "$SRC/main.tsx" ]; then
cat > "$SRC/main.tsx" <<'TS'
import React from 'react';
import { createRoot } from 'react-dom/client';
import AppShell from './AppShell';
const el = document.getElementById('root')!;
createRoot(el).render(<AppShell/>);
console.log('[boot] App mounted');
TS
fi

echo "✅ Done. Соберите проект: npm run build && npm run preview"