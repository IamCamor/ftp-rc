#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
SRC="$ROOT/src"
[ -d "$ROOT/frontend/src" ] && SRC="$ROOT/frontend/src"

mkdir -p "$SRC/components" "$SRC/pages" "$SRC/utils" "$SRC/assets"

############################################
# 1) config.ts — фиче-флаги провайдеров, ссылки на оферту/персональные данные/правила,
#    раздельные базовые пути для обычного API и auth-роутов (чтобы обойти 404 на /api/v1/auth/*)
############################################
cat > "$SRC/config.ts" <<'TS'
export type Providers = {
  google: boolean; vk: boolean; yandex: boolean; apple: boolean;
};

export type AppConfig = {
  apiBase: string;           // основной REST (/api/v1/*)
  authBase: string;          // базовый URL для /auth/* (без /api/v1)
  siteBase: string;
  images: {
    logoUrl: string;
    defaultAvatar: string;
    backgroundPattern: string;
  };
  icons: { [k: string]: string };
  banners: { feedEvery: number };
  auth: {
    enabled: boolean;
    providers: Providers;
    // пути на бэке, если отличаются — можно подменить
    routes: {
      login: string;            // POST
      register: string;         // POST
      oauthRedirect: (provider: keyof Providers) => string; // GET -> 302
    };
    // ссылки на документы
    links: {
      privacy: string;   // Перс. данные / Политика конф.
      offer: string;     // Публичная оферта
      terms: string;     // Правила пользования
    };
    // ограничения полей
    username: {
      min: number;
      max: number;
      pattern: RegExp;   // допустимые символы
    };
  };
};

const config: AppConfig = {
  apiBase: 'https://api.fishtrackpro.ru/api/v1',
  authBase: 'https://api.fishtrackpro.ru',
  siteBase: 'https://www.fishtrackpro.ru',
  images: {
    logoUrl: '/assets/logo.svg',
    defaultAvatar: '/assets/default-avatar.png',
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
    star: 'star',
    gift: 'redeem',
    friends: 'group',
    settings: 'settings',
    leaderboard: 'military_tech',
    ad: 'brand_awareness',
    google: 'google',
    vk: 'groups',
    yandex: 'language',
    apple: 'apple',
    edit: 'edit',
    image: 'image',
    save: 'save',
    login: 'login',
    logout: 'logout',
  },
  banners: { feedEvery: 5 },
  auth: {
    enabled: true,
    providers: { google: true, vk: true, yandex: true, apple: true },
    routes: {
      login: '/auth/login',
      register: '/auth/register',
      oauthRedirect: (p)=> `/auth/${p}/redirect`,
    },
    links: {
      privacy: 'https://www.fishtrackpro.ru/docs/privacy',
      offer:   'https://www.fishtrackpro.ru/docs/offer',
      terms:   'https://www.fishtrackpro.ru/docs/terms',
    },
    username: {
      min: 3,
      max: 24,
      pattern: /^[a-zA-Z0-9._-]+$/ as unknown as RegExp,
    }
  }
};

export default config;
TS

############################################
# 2) api.ts — разнесение apiBase/authBase, безопасные фолы на 404,
#    методы для auth + профиль/аватар
############################################
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

  if (res.status === 204) return undefined as unknown as T;

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
  return data as T;
}

function unwrap<T=any>(x: any, fallback: T): T {
  if (x == null) return fallback;
  if (Array.isArray(x)) return x as T;
  if (typeof x === 'object' && Array.isArray((x as any).data)) return (x as any).data as T;
  return x as T;
}

const base = config.apiBase;
const authBase = config.authBase;

/** FEED / MAP / DETAILS (как было) */
export async function feed(params: {limit?: number; offset?: number} = {}) {
  const q = new URLSearchParams();
  if (params.limit) q.set('limit', String(params.limit));
  if (params.offset) q.set('offset', String(params.offset));
  const r = await http<any>(`${base}/feed${q.toString()?`?${q.toString()}`:''}`);
  return unwrap<any[]>(r, []);
}
export async function points(bbox?: string, limit = 500) {
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

/** NOTIFICATIONS / PROFILE */
export async function notifications(){ const r = await http<any>(`${base}/notifications`); return unwrap<any[]>(r, []); }
export async function profileMe(){ return await http<any>(`${base}/profile/me`); }

/** WEATHER FAVS (local only) */
export function getWeatherFavs(): Array<{lat:number; lng:number; title?:string; id?:string|number}> {
  try { const raw = localStorage.getItem('weather_favs'); const parsed = raw ? JSON.parse(raw) : []; return Array.isArray(parsed) ? parsed : []; }
  catch { return []; }
}
export function saveWeatherFav(p: {lat:number; lng:number; title?:string}) {
  const list = getWeatherFavs(); list.push(p);
  try { localStorage.setItem('weather_favs', JSON.stringify(list)); } catch {}
  return list;
}

/** ADD CATCH / PLACE */
export async function addCatch(payload: any){ return await http(`${base}/catch`, {method:'POST', body: payload}); }
export async function addPlace(payload: any){ return await http(`${base}/place`, {method:'POST', body: payload}); }

/** AUTH (двухбазовый режим с запасным путём) */
async function postAuth<T=any>(path: string, body: any){
  try {
    return await http<T>(`${authBase}${path}`, {method:'POST', body, auth:false});
  } catch (e:any) {
    if (e.status === 404) {
      // fallback: иногда auth повешен и под /api/v1
      return await http<T>(`${base}${path.replace(/^\/auth/, '/auth')}`, {method:'POST', body, auth:false});
    }
    throw e;
  }
}

export async function login(email: string, password: string) {
  const r = await postAuth<{token:string}>(config.auth.routes.login, {email,password});
  if ((r as any)?.token) localStorage.setItem('token', (r as any).token);
  return r;
}
export async function register(name: string, email: string, password: string, username?: string, avatarUrl?: string) {
  const payload: any = {name, email, password};
  if (username) payload.username = username;
  if (avatarUrl) payload.photo_url = avatarUrl;
  const r = await postAuth<{token:string}>(config.auth.routes.register, payload);
  if ((r as any)?.token) localStorage.setItem('token', (r as any).token);
  return r;
}

/** OAuth — просто редиректим браузер на backend */
export function oauthStart(provider: keyof import('./config').Providers){
  const url = `${authBase}${config.auth.routes.oauthRedirect(provider)}`;
  window.location.href = url;
}

/** RATINGS / BANNERS / FRIENDS / BONUSES / SETTINGS */
export async function rateCatch(catchId: string|number, stars: number){ return await http(`${base}/catch/${catchId}/rating`, {method:'POST', body:{stars}}); }
export async function leaderboard(limit=20){ const r = await http<any>(`${base}/leaderboard?limit=${limit}`); return unwrap<any[]>(r, []); }

export async function friendsList(){ const r = await http<any>(`${base}/friends`); return unwrap<any[]>(r, []); }
export async function friendRequest(email: string){ return await http(`${base}/friends/request`, {method:'POST', body:{email}}); }
export async function friendApprove(requestId: string|number){ return await http(`${base}/friends/approve`, {method:'POST', body:{request_id:requestId}}); }
export async function friendRemove(userId: string|number){ return await http(`${base}/friends/remove`, {method:'POST', body:{user_id:userId}}); }

export async function bannersGet(slot: string){ const r = await http<any>(`${base}/banners?slot=${encodeURIComponent(slot)}`); return unwrap<any[]>(r, []); }

export async function bonusBalance(){ return await http<any>(`${base}/bonuses/balance`); }
export async function bonusHistory(limit=50){ const r = await http<any>(`${base}/bonuses/history?limit=${limit}`); return unwrap<any[]>(r, []); }
export async function bonusAward(action: 'like'|'share'|'add_catch'|'add_place', meta?: any){ return await http<any>(`${base}/bonuses/award`, {method:'POST', body:{action, meta}}); }

export async function settingsGet(){ return await http<any>(`${base}/settings`); }
export async function settingsUpdate(patch: any){ return await http<any>(`${base}/settings`, {method:'PATCH', body:patch}); }

/** Профильные апдейты (ник/аватар) — через settings */
export async function updateUsername(username: string){ return settingsUpdate({ username }); }
export async function updateAvatar(photo_url: string){ return settingsUpdate({ photo_url }); }
TS

############################################
# 3) Компонент кнопок соц-входа с фиче-флагами
############################################
cat > "$SRC/components/SocialAuth.tsx" <<'TS'
import React from 'react';
import config from '../config';
import Icon from './Icon';
import { oauthStart } from '../api';

const ProviderBtn: React.FC<{p:'google'|'vk'|'yandex'|'apple'; label:string}> = ({p,label}) => (
  <button type="button" className="btn" onClick={()=>oauthStart(p)} aria-label={label} title={label}>
    <Icon name={config.icons[p]} /> <span className="hide-sm">{label}</span>
  </button>
);

const SocialAuth: React.FC = () => {
  if (!config.auth.enabled) return null;
  const { providers } = config.auth;
  return (
    <div className="row" style={{gap:8, flexWrap:'wrap'}}>
      {providers.google && <ProviderBtn p="google" label="Войти через Google" />}
      {providers.vk && <ProviderBtn p="vk" label="Войти через VK" />}
      {providers.yandex && <ProviderBtn p="yandex" label="Войти через Yandex" />}
      {providers.apple && <ProviderBtn p="apple" label="Войти через Apple" />}
    </div>
  );
};

export default SocialAuth;
TS

############################################
# 4) Страница входа
############################################
cat > "$SRC/pages/LoginPage.tsx" <<'TS'
import React, { useState } from 'react';
import { login } from '../api';
import { useNavigate, Link } from 'react-router-dom';
import Icon from '../components/Icon';
import SocialAuth from '../components/SocialAuth';
import config from '../config';
import { pushToast } from '../components/Toast';

const LoginPage: React.FC = () => {
  const nav = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');

  async function onSubmit(e:React.FormEvent){
    e.preventDefault();
    setErr(''); setBusy(true);
    try{
      await login(email, password);
      pushToast('Добро пожаловать!');
      nav('/feed', { replace:true });
    }catch(e:any){
      setErr(e?.message || 'Не удалось войти');
    }finally{ setBusy(false); }
  }

  return (
    <div className="container" style={{maxWidth:560}}>
      <h2 className="h2">Вход</h2>
      <form onSubmit={onSubmit} className="glass card grid">
        <label>Email</label>
        <input className="input" type="email" required value={email} onChange={e=>setEmail(e.target.value)} />
        <label>Пароль</label>
        <input className="input" type="password" required value={password} onChange={e=>setPassword(e.target.value)} />
        {err && <div className="muted" style={{color:'#ffb4b4'}}>{err}</div>}
        <button className="btn primary" disabled={busy}><Icon name={config.icons.login}/> Войти</button>
      </form>

      <div className="glass card" style={{marginTop:12}}>
        <div style={{marginBottom:8, fontWeight:600}}>Быстрый вход</div>
        <SocialAuth/>
      </div>

      <div className="muted" style={{marginTop:12}}>
        Нет аккаунта? <Link to="/register">Зарегистрироваться</Link>
      </div>
    </div>
  );
};
export default LoginPage;
TS

############################################
# 5) Страница регистрации: согласия + логин/аватар
############################################
cat > "$SRC/pages/RegisterPage.tsx" <<'TS'
import React, { useMemo, useState } from 'react';
import { register, updateAvatar, updateUsername } from '../api';
import { useNavigate, Link } from 'react-router-dom';
import Icon from '../components/Icon';
import SocialAuth from '../components/SocialAuth';
import config from '../config';
import { pushToast } from '../components/Toast';

const re = config.auth.username.pattern as unknown as RegExp;

const RegisterPage: React.FC = () => {
  const nav = useNavigate();
  const [name, setName] = useState('');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [avatarUrl, setAvatarUrl] = useState('');
  const [agreePrivacy, setAgreePrivacy] = useState(false);
  const [agreeOffer, setAgreeOffer] = useState(false);
  const [agreeTerms, setAgreeTerms] = useState(false);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');

  const usernameOk = useMemo(()=>{
    if (username.length < config.auth.username.min) return false;
    if (username.length > config.auth.username.max) return false;
    return re.test(username);
  },[username]);

  async function onSubmit(e:React.FormEvent){
    e.preventDefault();
    setErr('');
    if (!agreePrivacy || !agreeOffer || !agreeTerms) {
      setErr('Необходимо согласиться с документами.');
      return;
    }
    if (!usernameOk) {
      setErr('Некорректный логин. Разрешены латиница/цифры/._-');
      return;
    }
    setBusy(true);
    try{
      await register(name, email, password, username, avatarUrl || undefined);
      // дополнительно пробуем через settings, если бэк не принял в /auth/register
      if (username) await updateUsername(username).catch(()=>{});
      if (avatarUrl) await updateAvatar(avatarUrl).catch(()=>{});
      pushToast('Регистрация успешна');
      nav('/feed', { replace:true });
    }catch(e:any){
      setErr(e?.message || 'Не удалось зарегистрироваться');
    }finally{ setBusy(false); }
  }

  return (
    <div className="container" style={{maxWidth:720}}>
      <h2 className="h2">Регистрация</h2>
      <form onSubmit={onSubmit} className="glass card grid">
        <div className="grid" style={{gridTemplateColumns:'1fr 1fr', gap:12}}>
          <div>
            <label>Имя</label>
            <input className="input" required value={name} onChange={e=>setName(e.target.value)} />
          </div>
          <div>
            <label>Логин</label>
            <input className="input" required value={username} onChange={e=>setUsername(e.target.value)} placeholder="a-z 0-9 . _ -" />
            <small className="muted">
              {config.auth.username.min}–{config.auth.username.max} символов
            </small>
          </div>
          <div>
            <label>Email</label>
            <input className="input" type="email" required value={email} onChange={e=>setEmail(e.target.value)} />
          </div>
          <div>
            <label>Пароль</label>
            <input className="input" type="password" required value={password} onChange={e=>setPassword(e.target.value)} />
          </div>
          <div style={{gridColumn:'1 / span 2'}}>
            <label><Icon name={config.icons.image}/> URL аватарки (по желанию)</label>
            <input className="input" type="url" placeholder="https://..." value={avatarUrl} onChange={e=>setAvatarUrl(e.target.value)} />
          </div>
        </div>

        <div className="grid" style={{gap:8, marginTop:8}}>
          <label className="row">
            <input type="checkbox" checked={agreePrivacy} onChange={e=>setAgreePrivacy(e.target.checked)} />
            <span>Согласие на обработку персональных данных (<a href={config.auth.links.privacy} target="_blank">политика</a>)</span>
          </label>
          <label className="row">
            <input type="checkbox" checked={agreeOffer} onChange={e=>setAgreeOffer(e.target.checked)} />
            <span>Согласие с <a href={config.auth.links.offer} target="_blank">офертой</a></span>
          </label>
          <label className="row">
            <input type="checkbox" checked={agreeTerms} onChange={e=>setAgreeTerms(e.target.checked)} />
            <span>Согласие с <a href={config.auth.links.terms} target="_blank">правилами пользования</a></span>
          </label>
        </div>

        {err && <div className="muted" style={{color:'#ffb4b4'}}>{err}</div>}
        <button className="btn primary" disabled={busy}><Icon name={config.icons.save}/> Создать аккаунт</button>
      </form>

      <div className="glass card" style={{marginTop:12}}>
        <div style={{marginBottom:8, fontWeight:600}}>Или зарегистрируйтесь через соцсети</div>
        <SocialAuth/>
      </div>

      <div className="muted" style={{marginTop:12}}>
        Уже с нами? <Link to="/login">Войти</Link>
      </div>
    </div>
  );
};
export default RegisterPage;
TS

############################################
# 6) Иконки (если нет) — лёгкий компонент Material Symbols (у вас уже есть, оставим совместимым)
############################################
cat > "$SRC/components/Icon.tsx" <<'TS'
import React from 'react';

const Icon: React.FC<{name:string; size?:number; className?:string; title?:string}> = ({name, size=24, className='', title}) => (
  <span
    className={`material-symbols-rounded ${className}`}
    style={{fontSize: size, lineHeight: 1, display:'inline-flex', verticalAlign:'middle'}}
    aria-hidden={title? undefined : true}
    title={title}
  >
    {name}
  </span>
);

export default Icon;
TS

############################################
# 7) Маршруты: если AppRoot.tsx отсутствует — не трогаем. Если есть — гарантируем, что пути есть.
#    (Добавлять не будем тут, вы их уже подключили. Страницы экспортированы по default.)
############################################

echo "✅ Auth pack applied. Now run: npm i && npm run build"