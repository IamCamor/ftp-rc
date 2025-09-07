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
/* replaced by patch */>(`${base}/auth/login`, {method:'POST', body:{email,password}, auth:false});
  if (r?.token) localStorage.setItem('token', r.token);
  return r;
}
/* replaced by patch */>(`${base}/auth/register`, {method:'POST', body:{name,email,password}, auth:false});
  if (r?.token) localStorage.setItem('token', r.token);
  return r;
}
export function logout(){ try { localStorage.removeItem('token'); } catch {} }
export function isAuthed(){ return !!getToken(); }
const authBase = config.authBase;

// ---- AUTH (patched) ----
export async function login(email:string, password:string){
  const r = await (await import('./api')).defaultFetch?.(`${config.authBase}/auth/login`)?.catch?.(()=>null);
  // если defaultFetch отсутствует — используем локальный http:
  // @ts-ignore
  if(!r){
    const http = (await import('./api')).http || (async (u:string,o:any)=> { const res=await fetch(u,{method:'POST',headers:{'Content-Type':'application/json','Accept':'application/json'},body:JSON.stringify(o.body)}); return res.json(); });
  }
  // финальная реализация
  const res = await fetch(`${config.authBase}/auth/login`, {method:'POST', headers:{'Content-Type':'application/json','Accept':'application/json'}, body: JSON.stringify({email,password})});
  const data = await res.json();
  if(!res.ok) throw new Error(data?.message||'Login failed');
  if(data?.token) localStorage.setItem('token', data.token);
  return data;
}
export async function register(name:string, email:string, password:string, username?:string, avatarUrl?:string){
  const body:any={name,email,password}; if(username) body.username=username; if(avatarUrl) body.photo_url=avatarUrl;
  const res = await fetch(`${config.authBase}/auth/register`, {method:'POST', headers:{'Content-Type':'application/json','Accept':'application/json'}, body: JSON.stringify(body)});
  const data = await res.json();
  if(!res.ok) throw new Error(data?.message||'Register failed');
  if(data?.token) localStorage.setItem('token', data.token);
  return data;
}
export function oauthStart(provider:'google'|'vk'|'yandex'|'apple'){
  window.location.href = `${config.authBase}/auth/${provider}/redirect`;
}
