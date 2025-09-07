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
