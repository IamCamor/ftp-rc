import config from './config';

type FetchOpts = {
  method?: 'GET'|'POST'|'PUT'|'DELETE',
  body?: any,
  headers?: Record<string,string>,
  credentials?: RequestCredentials
};

async function http<T=any>(path:string, opts:FetchOpts = {}): Promise<T> {
  const url = path.startsWith('http') ? path : `${config.apiBase}${path}`;
  const headers:Record<string,string> = { 'Accept':'application/json' };
  let body: BodyInit | undefined;
  if (opts.body !== undefined) {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(opts.body);
  }
  const res = await fetch(url, {
    method: opts.method ?? 'GET',
    headers: { ...headers, ...(opts.headers ?? {}) },
    credentials: opts.credentials ?? 'include',
    body
  });

  if (res.status === 204) return undefined as unknown as T;
  const text = await res.text();
  let json:any; try { json = text ? JSON.parse(text) : {}; } catch { json = text; }
  if (!res.ok) {
    const e:any = new Error((json && (json.message || json.error)) || `HTTP ${res.status}`);
    e.status = res.status; e.payload = json; throw e;
  }
  return json as T;
}

function normalizeArray(payload:any): any[] {
  if (Array.isArray(payload)) return payload;
  if (!payload) return [];
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.results)) return payload.results;
  if (Array.isArray(payload.rows)) return payload.rows;
  if (typeof payload === 'object') {
    const vals = Object.values(payload);
    if (vals.length && vals.every(v => typeof v === 'object')) return vals as any[];
  }
  return [];
}

// Map
export type PointsQuery = { limit?: number; bbox?: string | [number,number,number,number]; filter?: string };
export async function points(q: PointsQuery = {}): Promise<any[]> {
  const p = new URLSearchParams();
  if (q.limit) p.set('limit', String(q.limit));
  if (q.filter) p.set('filter', q.filter);
  if (q.bbox) p.set('bbox', Array.isArray(q.bbox) ? q.bbox.join(',') : q.bbox);
  const res = await http<any>(`/api/v1/map/points?${p.toString()}`);
  return normalizeArray(res);
}

// Feed
export async function feed(limit=10, offset=0): Promise<any[]> {
  const res = await http<any>(`/api/v1/feed?limit=${limit}&offset=${offset}`);
  return normalizeArray(res);
}

// Profile
export async function profileMe(): Promise<any> {
  return http<any>('/api/v1/profile/me');
}

// Notifications
export async function notifications(): Promise<any[]> {
  const res = await http<any>('/api/v1/notifications');
  return normalizeArray(res);
}

// Weather favs (локально)
const LS_KEY = 'weather_favs_v1';
export type WeatherFav = { lat:number; lng:number; name:string };
export function getWeatherFavs(): WeatherFav[] {
  try { return JSON.parse(localStorage.getItem(LS_KEY) || '[]'); } catch { return []; }
}
export async function saveWeatherFav(f: WeatherFav): Promise<void> {
  const list = getWeatherFavs(); list.push(f);
  localStorage.setItem(LS_KEY, JSON.stringify(list));
}
