import config from './config';

type FetchOpts = {
  method?: 'GET'|'POST'|'PUT'|'DELETE',
  body?: any,
  headers?: Record<string,string>,
  credentials?: RequestCredentials
};

function joinUrl(base:string, path:string) {
  if (path.startsWith('http')) return path;
  const b = base.replace(/\/+$/,''); const p = path.replace(/^\/+/,'');
  return `${b}/${p}`;
}

async function httpRaw(url:string, opts:FetchOpts): Promise<Response> {
  return fetch(url, {
    method: opts.method ?? 'GET',
    headers: opts.headers,
    credentials: opts.credentials ?? 'include',
    body: opts.body
  });
}

/**
 * Пробуем несколько префиксов:
 *   /api/v1/xxx  → /api/xxx → /xxx
 */
async function httpTry<T=any>(path:string, opts:FetchOpts = {}): Promise<T> {
  const variants = [
    path.startsWith('/api/v1/') ? path : `/api/v1${path.startsWith('/')?path:`/${path}`}`,
    path.startsWith('/api/') ? path : `/api${path.startsWith('/')?path:`/${path}`}`,
    path.startsWith('/') ? path : `/${path}`,
  ];

  let lastErr:any = null;
  for (const v of variants) {
    try {
      const url = joinUrl(config.apiBase, v);
      const res = await httpRaw(url, opts);
      const text = await res.text();
      let json:any; try { json = text ? JSON.parse(text) : {}; } catch { json = text; }
      if (!res.ok) { lastErr = {status:res.status, payload:json}; continue; }
      return json as T;
    } catch (e:any) {
      lastErr = e;
      continue;
    }
  }
  const err:any = new Error((lastErr && (lastErr.payload?.message || lastErr.payload?.error)) || 'Network/Route error');
  err.cause = lastErr; throw err;
}

function normalizeArray(payload:any): any[] {
  if (Array.isArray(payload)) return payload;
  if (!payload) return [];
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.results)) return payload.results;
  if (Array.isArray(payload.rows)) return payload.rows;
  return [];
}

export type PointsQuery = { limit?: number; bbox?: string | [number,number,number,number]; filter?: string };
export async function points(q: PointsQuery = {}): Promise<any[]> {
  const p = new URLSearchParams();
  if (q.limit) p.set('limit', String(q.limit));
  if (q.filter) p.set('filter', q.filter);
  if (q.bbox) p.set('bbox', Array.isArray(q.bbox) ? q.bbox.join(',') : q.bbox);
  const res = await httpTry<any>(`/map/points?${p.toString()}`, { method:'GET' });
  return normalizeArray(res);
}

export async function feed(limit=10, offset=0): Promise<any[]> {
  const res = await httpTry<any>(`/feed?limit=${limit}&offset=${offset}`, { method:'GET' });
  return normalizeArray(res);
}

export async function profileMe(): Promise<any> {
  return httpTry<any>('/profile/me', { method:'GET' });
}

export async function notifications(): Promise<any[]> {
  const res = await httpTry<any>('/notifications', { method:'GET' });
  return normalizeArray(res);
}

/** Форматируем ISO/строку в MySQL DATETIME (локально) */
export function toMysqlDatetime(input: string|Date): string {
  const d = typeof input === 'string' ? new Date(input) : input;
  const pad = (n:number)=> (n<10?'0':'')+n;
  return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

/** submit multipart */
async function postMultipart<T=any>(path:string, data:Record<string,any>): Promise<T> {
  const fd = new FormData();
  Object.entries(data).forEach(([k,v])=>{
    if (v === undefined || v === null) return;
    if (Array.isArray(v)) v.forEach((vv)=> fd.append(k, vv as any));
    else fd.append(k, v as any);
  });
  return httpTry<T>(path, { method:'POST', body: fd, credentials:'include' });
}

/** submit json */
async function postJson<T=any>(path:string, data:any): Promise<T> {
  return httpTry<T>(path, { method:'POST', body: JSON.stringify(data), headers:{'Content-Type':'application/json'} });
}

/** ====== Catch ====== */
export type CatchPayload = {
  lat:number; lng:number;
  species:string;
  length?:number; weight?:number;
  style?:string; lure?:string; tackle?:string;
  notes?:string;
  photo?: File|null;
  caught_at: string; // YYYY-MM-DD HH:mm:ss
  privacy?: 'all'|'friends'|'private';
};
export async function createCatch(payload: CatchPayload): Promise<any> {
  const body:any = { ...payload };
  if (payload.photo) body.photo = payload.photo;
  return postMultipart('/catch', body);
}

/** ====== Place ====== */
export type PlacePayload = {
  title:string;
  description?:string;
  lat:number; lng:number;
  water_type?: 'river'|'lake'|'sea'|'pond'|'other';
  access?: 'free'|'paid'|'restricted';
  season?: string;
  tags?: string;
  photos?: File[];
  privacy?: 'all'|'friends'|'private';
};
export async function createPlace(payload: PlacePayload): Promise<any> {
  const body:any = { ...payload };
  if (payload.photos && payload.photos.length) {
    body.photos = payload.photos; // backend должен принять массив
  }
  return postMultipart('/places', body);
}
export async function getPlaceById(id: string|number): Promise<any> {
  return httpTry<any>(`/places/${id}`, { method:'GET' });
}

const LS_KEY = 'weather_favs_v1';
export type WeatherFav = { lat:number; lng:number; name:string };
export function getWeatherFavs(): WeatherFav[] {
  try { return JSON.parse(localStorage.getItem(LS_KEY) || '[]'); } catch { return []; }
}
export async function saveWeatherFav(f: WeatherFav): Promise<void> {
  const list = getWeatherFavs(); list.push(f);
  localStorage.setItem(LS_KEY, JSON.stringify(list));
}

