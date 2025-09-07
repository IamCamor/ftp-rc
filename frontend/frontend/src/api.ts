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

/** FEED */
export async function feed(params: {limit?: number; offset?: number} = {}) {
  const q = new URLSearchParams();
  if (params.limit) q.set('limit', String(params.limit));
  if (params.offset) q.set('offset', String(params.offset));
  const r = await http<any>(`${base}/feed${q.toString()?`?${q.toString()}`:''}`);
  return unwrap<any[]>(r, []);
}

/** MAP */
export async function points(bbox?: string, limit = 500) {
  const q = new URLSearchParams();
  q.set('limit', String(limit));
  if (bbox) q.set('bbox', bbox);
  const r = await http<any>(`${base}/map/points?${q.toString()}`);
  return unwrap<any[]>(r, []);
}

/** DETAILS */
export async function catchById(id: string|number){ return await http<any>(`${base}/catch/${id}`); }
export async function placeById(id: string|number){ return await http<any>(`${base}/place/${id}`); }

/** INTERACTIONS */
export async function addCatchComment(id:number|string, text:string){
  return await http(`${base}/catch/${id}/comments`, {method:'POST', body:{text}});
}
export async function likeCatch(id:number|string){
  return await http(`${base}/catch/${id}/like`, {method:'POST'});
}

/** NOTIFICATIONS */
export async function notifications() {
  const r = await http<any>(`${base}/notifications`);
  return unwrap<any[]>(r, []);
}

/** PROFILE */
export async function profileMe(){ return await http<any>(`${base}/profile/me`); }

/** WEATHER FAVS (local) */
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

/** ADD CATCH / PLACE */
export async function addCatch(payload: {
  species?: string; length?: number; weight?: number;
  style?: string; lure?: string; tackle?: string;
  notes?: string; photo_url?: string;
  lat?: number; lng?: number; caught_at?: string;
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

/** AUTH */
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

/** RATINGS */
export async function rateCatch(catchId: string|number, stars: number){
  return await http(`${base}/catch/${catchId}/rating`, {method:'POST', body:{stars}});
}
export async function leaderboard(limit=20){
  const r = await http<any>(`${base}/leaderboard?limit=${limit}`);
  return unwrap<any[]>(r, []);
}

/** FRIENDS */
export async function friendsList(){
  const r = await http<any>(`${base}/friends`);
  return unwrap<any[]>(r, []);
}
export async function friendRequest(email: string){
  return await http(`${base}/friends/request`, {method:'POST', body:{email}});
}
export async function friendApprove(requestId: string|number){
  return await http(`${base}/friends/approve`, {method:'POST', body:{request_id:requestId}});
}
export async function friendRemove(userId: string|number){
  return await http(`${base}/friends/remove`, {method:'POST', body:{user_id:userId}});
}

/** BANNERS */
export async function bannersGet(slot: string){
  const r = await http<any>(`${base}/banners?slot=${encodeURIComponent(slot)}`);
  return unwrap<any[]>(r, []);
}

/** BONUSES */
export async function bonusBalance(){
  return await http<any>(`${base}/bonuses/balance`);
}
export async function bonusHistory(limit=50){
  const r = await http<any>(`${base}/bonuses/history?limit=${limit}`);
  return unwrap<any[]>(r, []);
}
/** Пример начисления за действие (like/share/add) — если бэк готов */
export async function bonusAward(action: 'like'|'share'|'add_catch'|'add_place', meta?: any){
  return await http<any>(`${base}/bonuses/award`, {method:'POST', body:{action, meta}});
}

/** SETTINGS */
export async function settingsGet(){
  return await http<any>(`${base}/settings`);
}
export async function settingsUpdate(patch: any){
  return await http<any>(`${base}/settings`, {method:'PATCH', body:patch});
}
