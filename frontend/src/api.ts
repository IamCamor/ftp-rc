import config from './config';

type FetchOpts = { method?: 'GET'|'POST'|'PUT'|'DELETE'; body?: any; headers?: Record<string,string>; credentials?: RequestCredentials };

async function http<T = any>(path: string, opts: FetchOpts = {}): Promise<T> {
  const url = path.startsWith('http') ? path : `${config.apiBase}${path}`;
  const headers: Record<string,string> = { 'Accept': 'application/json' };
  let body: BodyInit | undefined;

  if (opts.body !== undefined) {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(opts.body);
  }

  const res = await fetch(url, {
    method: opts.method ?? 'GET',
    headers: { ...headers, ...(opts.headers ?? {}) },
    credentials: 'include', // чтобы работали куки/сессии
    body
  });

  // Некоторые наши ручки возвращают 204 без body
  if (res.status === 204) return undefined as unknown as T;

  const text = await res.text();
  let json: any;
  try { json = text ? JSON.parse(text) : {}; } catch { json = text; }

  if (!res.ok) {
    const e: any = new Error((json && (json.message || json.error)) || `HTTP ${res.status}`);
    e.status = res.status; e.payload = json;
    throw e;
  }
  return json as T;
}

export type PointsQuery = { limit?: number; bbox?: string | [number,number,number,number]; filter?: string };

function normalizeArray(payload: any): any[] {
  if (Array.isArray(payload)) return payload;
  if (payload == null) return [];
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.results)) return payload.results;
  if (Array.isArray(payload.rows)) return payload.rows;
  // иногда прилетает объект с числовыми ключами — превратим в массив значений
  if (typeof payload === 'object') {
    const vals = Object.values(payload);
    if (vals.length && vals.every(v => typeof v === 'object')) return vals as any[];
  }
  return [];
}

// === MAP ===
export async function points(q: PointsQuery = {}): Promise<any[]> {
  const p = new URLSearchParams();
  if (q.limit) p.set('limit', String(q.limit));
  if (q.filter) p.set('filter', q.filter);
  if (q.bbox) {
    const s = Array.isArray(q.bbox) ? q.bbox.join(',') : q.bbox;
    p.set('bbox', s);
  }
  const res = await http<any>(`/map/points?${p.toString()}`);
  return normalizeArray(res);
}

// === FEED ===
export async function feed(limit = 10, offset = 0): Promise<any[]> {
  const res = await http<any>(`/feed?limit=${limit}&offset=${offset}`);
  return normalizeArray(res);
}

// === PROFILE ===
export async function profileMe(): Promise<any> {
  return http<any>('/profile/me');
}

// === NOTIFICATIONS ===
export async function notifications(): Promise<any[]> {
  const res = await http<any>('/notifications');
  return normalizeArray(res);
}

// === WEATHER FAVS (локально, пока бэкенд не готов) ===
const LS_KEY = 'weather_favs_v1';
export type WeatherFav = { lat: number, lng: number, name: string };
export function getWeatherFavs(): WeatherFav[] {
  try { return JSON.parse(localStorage.getItem(LS_KEY) || '[]'); } catch { return []; }
}
export async function saveWeatherFav(f: WeatherFav): Promise<void> {
  const list = getWeatherFavs();
  list.push(f);
  localStorage.setItem(LS_KEY, JSON.stringify(list));
}
