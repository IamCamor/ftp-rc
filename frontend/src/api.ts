import config from './config';

type FetchOpts = {
  method?: 'GET'|'POST'|'PUT'|'DELETE',
  body?: any,
  headers?: Record<string,string>,
  credentials?: RequestCredentials
};

function joinUrl(base:string, path:string) {
  if (!base) return path;
  if (path.startsWith('http')) return path;
  const b = base.replace(/\/+$/,''); const p = path.replace(/^\/+/,'');
  return `${b}/${p}`;
}

function dedupe<T>(arr:T[]):T[] {
  const seen = new Set<string>();
  return arr.filter((x:any) => {
    const key = String(x || '');
    if (seen.has(key)) return false;
    seen.add(key); return true;
  });
}

async function httpRaw(url:string, opts:FetchOpts): Promise<{res:Response, raw:string, json:any}> {
  const res = await fetch(url, {
    method: opts.method ?? 'GET',
    headers: opts.headers,
    credentials: opts.credentials ?? 'include',
    body: opts.body,
    // mode: 'cors' // по умолчанию так и есть в браузере
  });
  const raw = await res.text();
  let json:any;
  try { json = raw ? JSON.parse(raw) : {}; } catch { json = raw; }
  return { res, raw, json };
}

/**
 * Пробуем несколько баз + префиксов путей.
 * Базы:
 *   1) config.apiBase
 *   2) window.__API_BASE__
 *   3) window.location.origin (поддержка reverse-proxy на том же домене)
 *
 * Префиксы:
 *   /api/v1  →  /api  →  ''
 */
export async function httpTry<T=any>(path:string, opts:FetchOpts = {}): Promise<T> {
  const bases = dedupe<string>([
    config.apiBase || '',
    (typeof window !== 'undefined' && (window as any).__API_BASE__) || '',
    (typeof window !== 'undefined' && window.location?.origin) || ''
  ]).filter(Boolean);

  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  const pathVariants = dedupe<string>([
    normalizedPath.startsWith('/api/v1/') ? normalizedPath : `/api/v1${normalizedPath}`,
    normalizedPath.startsWith('/api/')    ? normalizedPath : `/api${normalizedPath}`,
    normalizedPath
  ]);

  const tried: {url:string, status?:number, note?:string}[] = [];
  let lastErr:any = null;

  for (const base of bases) {
    for (const pv of pathVariants) {
      const url = joinUrl(base, pv);
      try {
        const {res, json} = await httpRaw(url, opts);
        tried.push({url, status:res.status});
        if (!res.ok) { lastErr = {status:res.status, payload:json}; continue; }
        return json as T;
      } catch (e:any) {
        tried.push({url, note: e?.message || 'fetch error'});
        lastErr = e;
        continue;
      }
    }
  }

  if (config.debugNetwork && typeof window !== 'undefined') {
    console.groupCollapsed(`🔴 httpTry fail: ${path}`);
    console.table(tried);
    console.groupEnd();
  }

  const msg =
    (lastErr && (lastErr.payload?.message || lastErr.payload?.error)) ||
    (typeof lastErr?.status === 'number' ? `HTTP ${lastErr.status}` : (lastErr?.message || 'Network/Route error'));

  const err:any = new Error(msg);
  (err as any).tried = tried;
  throw err;
}

/** ---------- Вспомогательные хелперы ---------- */
function normalizeArray(payload:any): any[] {
  if (Array.isArray(payload)) return payload;
  if (!payload) return [];
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.results)) return payload.results;
  if (Array.isArray(payload.rows)) return payload.rows;
  return [];
}

/** Простой ping для проверки доступности API */
export async function ping(): Promise<{ok:boolean, base:string}|null> {
  const bases = dedupe<string>([
    config.apiBase || '',
    (typeof window !== 'undefined' && (window as any).__API_BASE__) || '',
    (typeof window !== 'undefined' && window.location?.origin) || ''
  ]).filter(Boolean);

  for (const base of bases) {
    try {
      const u = joinUrl(base, '/api/health');
      const {res} = await httpRaw(u, {method:'GET'});
      if (res.ok) return {ok:true, base};
    } catch {}
  }
  return null;
}

/** ---------- Endpoints ---------- */
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

/** Форматирование даты в MySQL DATETIME (локально) */
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
    body.photos = payload.photos;
  }
  return postMultipart('/places', body);
}

export async function getPlaceById(id: string|number): Promise<any> {
  return httpTry<any>(`/places/${id}`, { method:'GET' });
}
