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
