#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"

# --- 1) CONFIG c feature flags и дефолтами (чтобы не падало, если что-то не задано)
cat > "$ROOT/frontend/src/config.ts" <<'TS'
const config = {
  apiBase: (import.meta as any).env?.VITE_API_BASE ?? 'https://api.fishtrackpro.ru/api/v1',
  siteBase: (import.meta as any).env?.VITE_SITE_BASE ?? 'https://www.fishtrackpro.ru',
  assets: {
    logoUrl: '/logo.svg',
    defaultAvatar: '/default-avatar.png',
  },
  flags: {
    glass: true,
    // если на бэке нет ручек /api/v1/auth/login|register — выключаем password auth
    authPasswordEnabled: false,
    authOAuthEnabled: true,
    notificationsEnabled: false, // включите, когда появится /api/v1/notifications
    profileEnabled: false,        // включите, когда появится /api/v1/profile/me
    requireAuthForWeatherSave: false,
  },
  legal: {
    privacyConsentUrl: '/legal/privacy',
    offerUrl: '/legal/offer',
    rulesUrl: '/legal/rules',
  },
  providers: {
    google:  { enabled: true,  path: '/auth/google/redirect' },
    vk:      { enabled: true,  path: '/auth/vk/redirect' },
    yandex:  { enabled: true,  path: '/auth/yandex/redirect' },
    apple:   { enabled: true,  path: '/auth/apple/redirect' },
  },
  banners: {
    enabled: true,
    slots: ['feed.top','feed.bottom','map.bottom'],
  },
};
export default config;
TS

# --- 2) API — единый клиент + безопасные заглушки, чтобы сборка не падала
cat > "$ROOT/frontend/src/api.ts" <<'TS'
import config from './config';

type Json = any;
type ReqOpts = { method?: string; body?: any; auth?: boolean; headers?: Record<string,string> };

async function request<T=Json>(path: string, opts: ReqOpts = {}): Promise<T> {
  const url = path.startsWith('http') ? path : `${config.apiBase}${path}`;
  const headers: Record<string,string> = { 'Accept':'application/json' };
  let body: BodyInit | undefined;

  if (opts.body instanceof FormData) {
    body = opts.body;
  } else if (opts.body !== undefined) {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(opts.body);
  }

  const token = localStorage.getItem('token');
  if (opts.auth !== false && token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(url, { method: opts.method ?? 'GET', headers, body, credentials: 'include' });
  if (!res.ok) {
    // Вернём осмысленную ошибку
    let msg = `HTTP ${res.status}`;
    try { const j = await res.json(); if (j?.message) msg += `: ${j.message}`; } catch {}
    const e: any = new Error(msg);
    e.status = res.status;
    throw e;
  }
  try { return await res.json(); } catch { return undefined as any; }
}

/** FEED */
export async function feed(limit=10, offset=0){
  return request(`/feed?limit=${limit}&offset=${offset}`);
}

/** MAP */
export async function points(params: {limit?:number; bbox?: string} = {}){
  const q: string[] = [];
  if (params.limit) q.push(`limit=${params.limit}`);
  if (params.bbox)  q.push(`bbox=${encodeURIComponent(params.bbox)}`);
  const qs = q.length ? `?${q.join('&')}` : '';
  return request(`/map/points${qs}`);
}
export async function pointById(id: string|number){
  return request(`/map/points/${id}`);
}

/** CATCH */
export async function catchById(id: string|number){
  return request(`/catch/${id}`);
}
export async function addCatchComment(id: string|number, text: string){
  return request(`/catch/${id}/comments`, { method:'POST', body:{ text } });
}
export async function likeCatch(id: string|number){
  return request(`/catch/${id}/like`, { method:'POST' });
}
export async function rateCatch(id: string|number, stars: number){
  return request(`/catch/${id}/rating`, { method:'POST', body:{ stars } });
}
export async function bonusAward(kind: string, meta?: any){
  return request(`/bonus/award`, { method:'POST', body:{ kind, meta } });
}

/** BANNERS (может отсутствовать на бэке — тогда молча вернём пусто) */
export async function bannersGet(slot: string){
  try {
    return await request(`/banners?slot=${encodeURIComponent(slot)}`);
  } catch (e:any){
    if (e?.status === 404) return [];
    throw e;
  }
}

/** PROFILE / NOTIFICATIONS — безопасные фолы */
export async function profileMe(){
  if (!config.flags.profileEnabled) return null;
  try { return await request(`/profile/me`); }
  catch(e:any){ if (e?.status===404) return null; throw e; }
}
export async function notifications(){
  if (!config.flags.notificationsEnabled) return [];
  try { return await request(`/notifications`); }
  catch(e:any){ if (e?.status===404) return []; throw e; }
}

/** AUTH */
export function isAuthed(){ return !!localStorage.getItem('token'); }
export async function logout(){ localStorage.removeItem('token'); return true; }

// заглушки для password-auth, если на бэке нет /api/v1/auth/*
export async function login(email: string, password: string){
  if (!config.flags.authPasswordEnabled) throw new Error('Password auth disabled');
  return request(`/auth/login`, { method:'POST', body:{ email, password }, auth:false });
}
export async function register(payload: {email:string; password:string; login:string; agreePrivacy:boolean; agreeRules:boolean}){
  if (!config.flags.authPasswordEnabled) throw new Error('Password auth disabled');
  return request(`/auth/register`, { method:'POST', body:payload, auth:false });
}

// сохранение точки погоды (только для авторизованных, по ТЗ)
export async function saveWeatherFav(lat:number,lng:number,label?:string){
  if (!isAuthed()) throw new Error('AUTH_REQUIRED');
  return request(`/weather/favs`, { method:'POST', body:{ lat,lng,label } });
}
TS

# --- 3) ИКОНКИ (универсальный компонент Material Symbols)
mkdir -p "$ROOT/frontend/src/components"
cat > "$ROOT/frontend/src/components/Icon.tsx" <<'TS'
import React from 'react';
type Props = { name: string; className?: string; style?: React.CSSProperties; title?: string };
/** Универсальные Material Symbols (иконки задаём строкой в конфиге/коде) */
export default function Icon({ name, className, style, title }: Props){
  return <span className={`material-symbols-rounded ${className??''}`} style={style} aria-hidden title={title}>{name}</span>;
}
export { Icon };
TS

# --- 4) GLASS-LAYOUT: AppShell + Header + BottomNav (стабильно во всех страницах)
cat > "$ROOT/frontend/src/components/AppShell.tsx" <<'TS'
import React from 'react';
import Header from './Header';
import BottomNav from './BottomNav';
import '../styles/app.css';

export default function AppShell({children}:{children:React.ReactNode}){
  return (
    <div className="app-root">
      <Header />
      <main className="app-main">{children}</main>
      <BottomNav />
    </div>
  );
}
TS

cat > "$ROOT/frontend/src/components/Header.tsx" <<'TS'
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';
import Icon from './Icon';

export default function Header(){
  const loc = useLocation();
  return (
    <header className="glass header">
      <Link to="/" className="brand">
        <img src={config.assets?.logoUrl} alt="logo" />
        <b>FishTrack Pro</b>
      </Link>
      <nav className="actions">
        <Link to="/weather" className={loc.pathname.startsWith('/weather')?'active':''}>
          <Icon name="cloud" />
          <span className="hide-sm">Погода</span>
        </Link>
        <Link to="/alerts" className={loc.pathname.startsWith('/alerts')?'active':''}>
          <Icon name="notifications" />
        </Link>
        <Link to="/profile" className={loc.pathname.startsWith('/profile')?'active':''}>
          <Icon name="account_circle" />
        </Link>
      </nav>
    </header>
  );
}
TS

cat > "$ROOT/frontend/src/components/BottomNav.tsx" <<'TS'
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import Icon from './Icon';

export default function BottomNav(){
  const loc = useLocation();
  const is = (p:string)=> loc.pathname===p || loc.pathname.startsWith(p+'/');
  return (
    <nav className="bottom-nav glass">
      <Link to="/" className={is('/')?'active':''}><Icon name="home" /><span>Лента</span></Link>
      <Link to="/map" className={is('/map')?'active':''}><Icon name="map" /><span>Карта</span></Link>
      <Link to="/add/catch" className={is('/add/catch')?'active':''}><Icon name="add_a_photo" /><span>Улов</span></Link>
      <Link to="/add/place" className={is('/add/place')?'active':''}><Icon name="add_location" /><span>Место</span></Link>
      <Link to="/profile" className={is('/profile')?'active':''}><Icon name="person" /><span>Профиль</span></Link>
    </nav>
  );
}
TS

# --- 5) Стили + Glassmorphism
mkdir -p "$ROOT/frontend/src/styles"
cat > "$ROOT/frontend/src/styles/app.css" <<'CSS'
@import url('https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,400,0,0');

:root {
  --bg: #0b1220;
  --fg: #e8eefc;
  --muted: #a3b2d1;
  --brand: #49a3ff;
}

html,body,#root { height:100%; }
body { margin:0; background: radial-gradient(1200px 600px at 20% -20%, rgba(73,163,255,.25), transparent 60%), var(--bg); color: var(--fg); font-family: system-ui, -apple-system, Segoe UI, Roboto, Inter, Arial, sans-serif; }

.app-root { min-height:100%; display:grid; grid-template-rows: auto 1fr auto; }
.app-main { padding: 16px; }

.glass {
  backdrop-filter: blur(10px);
  background: rgba(255,255,255,0.08);
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 16px;
}

.header {
  margin: 12px 12px 0;
  padding: 10px 12px;
  display:flex; align-items:center; justify-content:space-between;
}
.header .brand { display:flex; align-items:center; gap:10px; text-decoration:none; color: var(--fg); }
.header .brand img { height:28px; width:auto; }
.header .actions { display:flex; gap:10px; }
.header .actions a { color: var(--fg); text-decoration:none; padding:8px 10px; border-radius:12px; }
.header .actions a.active { background: rgba(73,163,255,.18); }

.bottom-nav {
  position: sticky; bottom: 0;
  margin: 12px; padding: 8px;
  display:grid; grid-template-columns: repeat(5,1fr); gap: 6px;
}
.bottom-nav a { display:flex; flex-direction:column; align-items:center; gap:4px; color: var(--fg); text-decoration:none; padding:8px 6px; border-radius:12px; font-size:12px; }
.bottom-nav a.active { background: rgba(73,163,255,.18); }

.card { padding:14px; border-radius:16px; }
.row { display:flex; align-items:center; gap:10px; }
.grid-3 { display:grid; grid-template-columns: repeat(3,1fr); gap:10px; }
.btn { display:inline-flex; align-items:center; gap:8px; padding:10px 14px; border-radius:12px; text-decoration:none; cursor:pointer; }
.btn.primary { background: var(--brand); color: #001b33; border: 0; }
.btn.ghost { background: rgba(255,255,255,.08); color: var(--fg); border: 1px solid rgba(255,255,255,.12); }
.input { width:100%; padding:10px 12px; border-radius:12px; border:1px solid rgba(255,255,255,.15); background: rgba(255,255,255,.05); color: var(--fg); }
.help { color: var(--muted); font-size: 12px; }
.sep { height:1px; background: rgba(255,255,255,.12); margin:10px 0; border-radius:1px; }
.hide-sm { display: none; }
@media (min-width: 480px){ .hide-sm{ display: inline; } }
CSS

# --- 6) Login / Register (OAuth + согласия)
mkdir -p "$ROOT/frontend/src/pages"
cat > "$ROOT/frontend/src/pages/LoginPage.tsx" <<'TS'
import React from 'react';
import config from '../config';
import AppShell from '../components/AppShell';
import Icon from '../components/Icon';

export default function LoginPage(){
  const oauth = config.flags.authOAuthEnabled;
  const pwd   = config.flags.authPasswordEnabled;

  const go = (path: string) => {
    const base = config.siteBase.replace(/\/+$/,'');
    const api = config.apiBase.replace(/\/api\/v1$/,''); // перейти на корень api-домена
    window.location.href = `${api}${path}`;
  };

  return (
    <AppShell>
      <div className="glass card" style={{maxWidth:520, margin:'12px auto', display:'grid', gap:12}}>
        <div className="row"><Icon name="login" /><b>Вход в аккаунт</b></div>
        {oauth && (
          <div style={{display:'grid',gap:8}}>
            {config.providers.google.enabled && (
              <button className="btn ghost" onClick={()=>go(config.providers.google.path)}><Icon name="google" /> Войти через Google</button>
            )}
            {config.providers.vk.enabled && (
              <button className="btn ghost" onClick={()=>go(config.providers.vk.path)}><Icon name="language" /> Войти через VK</button>
            )}
            {config.providers.yandex.enabled && (
              <button className="btn ghost" onClick={()=>go(config.providers.yandex.path)}><Icon name="travel_explore" /> Войти через Яндекс</button>
            )}
            {config.providers.apple.enabled && (
              <button className="btn ghost" onClick={()=>go(config.providers.apple.path)}><Icon name="apple" /> Войти через Apple</button>
            )}
          </div>
        )}

        {!oauth && !pwd && (
          <div className="help">Авторизация временно недоступна (отключена флагами).</div>
        )}

        <div className="sep" />
        <a href="/register" className="btn primary"><Icon name="how_to_reg" /> Регистрация</a>
      </div>
    </AppShell>
  );
}
TS

cat > "$ROOT/frontend/src/pages/RegisterPage.tsx" <<'TS'
import React, { useState } from 'react';
import config from '../config';
import AppShell from '../components/AppShell';
import Icon from '../components/Icon';
import { register } from '../api';

export default function RegisterPage(){
  const [email,setEmail] = useState('');
  const [login,setLogin] = useState('');
  const [password,setPassword] = useState('');
  const [agreePrivacy,setAgreePrivacy] = useState(false);
  const [agreeRules,setAgreeRules] = useState(false);
  const [msg,setMsg] = useState<string | null>(null);

  const can = config.flags.authPasswordEnabled;

  const submit = async (e:React.FormEvent)=>{
    e.preventDefault();
    setMsg(null);
    if (!agreePrivacy || !agreeRules) { setMsg('Нужно дать согласия'); return; }
    try{
      if (!can) throw new Error('Парольная регистрация отключена');
      await register({ email, password, login, agreePrivacy, agreeRules });
      setMsg('Регистрация успешна. Проверьте почту/вернитесь на вход.');
    }catch(err:any){
      setMsg(err?.message || 'Ошибка регистрации');
    }
  };

  return (
    <AppShell>
      <form onSubmit={submit} className="glass card" style={{maxWidth:560, margin:'12px auto', display:'grid', gap:12}}>
        <div className="row"><Icon name="person_add" /><b>Регистрация</b></div>

        <input placeholder="Логин" className="input" value={login} onChange={e=>setLogin(e.target.value)} />
        <input placeholder="Email" className="input" value={email} onChange={e=>setEmail(e.target.value)} />
        <input placeholder="Пароль" className="input" type="password" value={password} onChange={e=>setPassword(e.target.value)} />

        <label className="row" style={{gap:8}}>
          <input type="checkbox" checked={agreePrivacy} onChange={e=>setAgreePrivacy(e.target.checked)} />
          <span>Согласен на <a href={config.legal.privacyConsentUrl} target="_blank">обработку персональных данных</a></span>
        </label>
        <label className="row" style={{gap:8}}>
          <input type="checkbox" checked={agreeRules} onChange={e=>setAgreeRules(e.target.checked)} />
          <span>Согласен с <a href={config.legal.offerUrl} target="_blank">офертой</a> и <a href={config.legal.rulesUrl} target="_blank">правилами пользования</a></span>
        </label>

        {msg && <div className="help">{msg}</div>}

        <div className="row" style={{gap:8, flexWrap:'wrap'}}>
          <button className="btn primary" disabled={!can}><Icon name="check" /> Зарегистрироваться</button>
          <a className="btn ghost" href="/login"><Icon name="login" /> Уже есть аккаунт</a>
        </div>

        {!can && <div className="help">Парольная регистрация отключена — используйте вход через провайдеров на странице «Вход».</div>}
      </form>
    </AppShell>
  );
}
TS

# --- 7) Notifications/Profile — безопасный UI при отсутствии роутов
cat > "$ROOT/frontend/src/pages/NotificationsPage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import AppShell from '../components/AppShell';
import Icon from '../components/Icon';
import config from '../config';
import { notifications } from '../api';

type Notice = { id: string|number; title?: string; text?: string; created_at?: string };

export default function NotificationsPage(){
  const [items,setItems] = useState<Notice[]>([]);
  const [err,setErr] = useState<string| null>(null);
  const enabled = config.flags.notificationsEnabled;

  useEffect(()=>{
    let aborted = false;
    (async()=>{
      setErr(null);
      if (!enabled){ setItems([]); return; }
      try{
        const data = await notifications();
        if (!aborted) setItems(Array.isArray(data)? data : (data?.items ?? []));
      }catch(e:any){
        // если 404 — просто показываем пусто и подсказку
        setErr(e?.message ?? 'Ошибка загрузки');
      }
    })();
    return ()=>{ aborted = true; };
  },[enabled]);

  return (
    <AppShell>
      <div className="glass card" style={{display:'grid', gap:12}}>
        <div className="row"><Icon name="notifications" /><b>Уведомления</b></div>
        {!enabled && <div className="help">Функция пока не активирована (ожидаем роут /api/v1/notifications).</div>}
        {enabled && err && <div className="help">Не удалось загрузить уведомления: {err}</div>}
        {enabled && !err && items.length===0 && <div className="help">Уведомлений пока нет.</div>}
        {enabled && items.map(n=>(
          <div key={String(n.id)} className="glass card" style={{padding:10}}>
            <div className="row" style={{justifyContent:'space-between'}}>
              <b>{n.title ?? 'Уведомление'}</b>
              {n.created_at && <span className="help">{new Date(n.created_at).toLocaleString()}</span>}
            </div>
            {n.text && <div style={{marginTop:6}}>{n.text}</div>}
          </div>
        ))}
      </div>
    </AppShell>
  );
}
TS

cat > "$ROOT/frontend/src/pages/ProfilePage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import AppShell from '../components/AppShell';
import Icon from '../components/Icon';
import config from '../config';
import { profileMe, isAuthed, logout } from '../api';

export default function ProfilePage(){
  const [me,setMe] = useState<any>(null);
  const [ready,setReady] = useState(false);

  useEffect(()=>{
    let canceled=false;
    (async()=>{
      if (!isAuthed() || !config.flags.profileEnabled){
        setReady(true); return;
      }
      try{
        const data = await profileMe();
        if (!canceled) { setMe(data); setReady(true); }
      }catch{ if (!canceled) setReady(true); }
    })();
    return ()=>{ canceled=true; };
  },[]);

  return (
    <AppShell>
      <div className="glass card" style={{display:'grid', gap:12, maxWidth:720, margin:'0 auto'}}>
        <div className="row"><Icon name="account_circle" /><b>Профиль</b></div>

        {!isAuthed() && (
          <div className="row" style={{gap:8, flexWrap:'wrap'}}>
            <a className="btn primary" href="/login"><Icon name="login" /> Войти</a>
            <a className="btn ghost" href="/register"><Icon name="how_to_reg" /> Регистрация</a>
          </div>
        )}

        {isAuthed() && !config.flags.profileEnabled && (
          <div className="help">Профиль временно недоступен (нет /api/v1/profile/me). Функция будет включена позже.</div>
        )}

        {isAuthed() && config.flags.profileEnabled && ready && (
          <>
            <div className="row" style={{gap:12}}>
              <img src={me?.photo_url ?? config.assets.defaultAvatar} alt="avatar" style={{width:64,height:64,borderRadius:16}} />
              <div>
                <div><b>{me?.name ?? 'Без имени'}</b></div>
                <div className="help">{me?.email ?? ''}</div>
              </div>
            </div>
            <div className="sep" />
            <button className="btn ghost" onClick={()=>{ logout(); window.location.reload(); }}>
              <Icon name="logout" /> Выйти
            </button>
          </>
        )}
      </div>
    </AppShell>
  );
}
TS

# --- 8) MapScreen — фиксы по requireAuthForWeatherSave и общий контейнер
cat > "$ROOT/frontend/src/pages/MapScreen.tsx" <<'TS'
import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import AppShell from '../components/AppShell';
import Icon from '../components/Icon';
import config from '../config';
import { points, saveWeatherFav, isAuthed } from '../api';

declare global { interface Window { L:any } }

export default function MapScreen(){
  const mapEl = useRef<HTMLDivElement>(null);
  const [error,setError] = useState<string | null>(null);
  const [ready,setReady] = useState(false);
  const navigate = useNavigate();

  useEffect(()=>{
    let aborted = false;
    (async()=>{
      try{
        if (!window.L){
          // динамически подключаем leaflet css/js (без внешних либ)
          const css = document.createElement('link');
          css.rel='stylesheet'; css.href='https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
          document.head.appendChild(css);
          await new Promise(res=>{
            const s = document.createElement('script');
            s.src='https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'; s.onload=()=>res(null); document.body.appendChild(s);
          });
        }
        if (!mapEl.current) return;
        const L = window.L;
        const map = L.map(mapEl.current).setView([55.75,37.62], 9);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(map);

        const data = await points({ limit: 500 }).catch(()=>[]);
        const list = Array.isArray(data?.items) ? data.items : (Array.isArray(data)? data : []);
        list.forEach((p: any)=>{
          if (typeof p.lat!=='number' || typeof p.lng!=='number') return;
          const m = L.marker([p.lat,p.lng]).addTo(map);
          m.on('click', ()=>{
            const html = `
              <div style="min-width:180px">
                <b>${p.title ?? 'Точка'}</b><br/>
                <button id="toPlace" style="margin-top:6px">Открыть</button>
                <button id="toFav" style="margin-top:6px;margin-left:6px">Сохранить погоду</button>
              </div>`;
            m.bindPopup(html).openPopup();
            setTimeout(()=>{
              const btn = document.getElementById('toPlace');
              const fav = document.getElementById('toFav');
              btn?.addEventListener('click', ()=> navigate(`/place/${p.id}`));
              fav?.addEventListener('click', async ()=>{
                try{
                  if (config.flags?.requireAuthForWeatherSave && !isAuthed()){
                    alert('Нужно войти, чтобы сохранять точки погоды');
                    navigate('/login'); return;
                  }
                  await saveWeatherFav(p.lat,p.lng,p.title);
                  alert('Сохранено!');
                }catch(e:any){ alert(e?.message ?? 'Ошибка'); }
              });
            },0);
          });
        });

        if (!aborted) setReady(true);
      }catch(e:any){
        if (!aborted) setError(e?.message ?? 'Map init error');
      }
    })();
    return ()=>{ aborted=true; };
  },[]);

  return (
    <AppShell>
      <div className="glass card" style={{marginBottom:12}}>
        <div className="row" style={{justifyContent:'space-between'}}>
          <div className="row"><Icon name="map" /><b>Карта</b></div>
          <div className="row" style={{gap:8}}>
            <a className="btn ghost" href="/add/place"><Icon name="add_location" /> Добавить место</a>
            <a className="btn ghost" href="/add/catch"><Icon name="add_a_photo" /> Добавить улов</a>
          </div>
        </div>
      </div>
      {error && <div className="glass card">{error}</div>}
      <div ref={mapEl} style={{height:'65vh'}} className="glass"></div>
    </AppShell>
  );
}
TS

# --- 9) Простой AppRoot c единым лэйаутом и маршрутизацией (без динамических импортов)
cat > "$ROOT/frontend/src/AppRoot.tsx" <<'TS'
import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import FeedScreen from './pages/FeedScreen';
import MapScreen from './pages/MapScreen';
import CatchDetailPage from './pages/CatchDetailPage';
import AddCatchPage from './pages/AddCatchPage';
import AddPlacePage from './pages/AddPlacePage';
import NotificationsPage from './pages/NotificationsPage';
import ProfilePage from './pages/ProfilePage';
import WeatherPage from './pages/WeatherPage';
import PlaceDetailPage from './pages/PlaceDetailPage';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';

export default function AppRoot(){
  return (
    <Routes>
      <Route path="/" element={<FeedScreen />} />
      <Route path="/map" element={<MapScreen />} />
      <Route path="/catch/:id" element={<CatchDetailPage />} />
      <Route path="/place/:id" element={<PlaceDetailPage />} />
      <Route path="/add/catch" element={<AddCatchPage />} />
      <Route path="/add/place" element={<AddPlacePage />} />
      <Route path="/alerts" element={<NotificationsPage />} />
      <Route path="/profile" element={<ProfilePage />} />
      <Route path="/weather" element={<WeatherPage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
TS

# --- 10) main.tsx — монтируем AppRoot, логируем старт
cat > "$ROOT/frontend/src/main.tsx" <<'TS'
import React from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import AppRoot from './AppRoot';

console.log('[boot] App mounted');
const el = document.getElementById('root')!;
createRoot(el).render(
  <BrowserRouter>
    <AppRoot />
  </BrowserRouter>
);
TS

echo "✅ Патч применён. Сборка: cd frontend && npm run build"