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
