import cfgDefault, { config as cfgNamed } from './config';

const cfg = (cfgNamed ?? cfgDefault);

/** Базовый fetch с общими заголовками/куками и автообработкой ошибок */
async function http<T = any>(path: string, init: RequestInit = {}): Promise<T> {
  const base = cfg.apiBase?.replace(/\/+$/,'') || '';
  const url  = `${base}${path.startsWith('/') ? '' : '/'}${path}`;
  const headers: HeadersInit = {
    Accept: 'application/json',
    ...(init.body ? {'Content-Type':'application/json'} : {}),
    ...(init.headers || {}),
  };
  const res = await fetch(url, {
    method: init.method ?? 'GET',
    credentials: 'include',             // важно для сессии
    headers,
    body: init.body as any,
  });

  // Иногда бек может прислать 204 без тела
  if (res.status === 204) return undefined as any;

  let data: any = null;
  const text = await res.text();
  try { data = text ? JSON.parse(text) : null; } catch { data = text; }

  if (!res.ok) {
    const msg = (data && (data.message || data.error)) || res.statusText;
    const err: any = new Error(`HTTP ${res.status}: ${msg}`);
    err.status = res.status;
    err.data = data;
    throw err;
  }
  return data as T;
}

/** Лента */
export async function feed(params: { limit?: number; offset?: number } = {}) {
  const q = new URLSearchParams();
  if (params.limit  != null) q.set('limit',  String(params.limit));
  if (params.offset != null) q.set('offset', String(params.offset));
  return http<{ items: any[]; nextOffset?: number }>(`/feed?${q.toString()}`);
}

/** Точки карты */
export async function points(params: { limit?: number; bbox?: string; filter?: string } = {}) {
  const q = new URLSearchParams();
  if (params.limit  != null) q.set('limit',  String(params.limit));
  if (params.bbox)           q.set('bbox',   params.bbox);
  if (params.filter)         q.set('filter', params.filter);
  return http<any[]>(`/map/points?${q.toString()}`);
}

/** Профиль */
export async function getProfile() {
  return http(`/profile/me`);
}

/** Уведомления */
export async function getNotifications() {
  return http<any[]>(`/notifications`);
}

/** Деталь улова */
export async function getCatchById(id: string|number) {
  return http(`/catch/${id}`);
}

/** Комментарий к улову */
export async function addComment(catchId: string|number, payload: { text: string }) {
  return http(`/catch/${catchId}/comments`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

/** Создать место */
export async function addPlace(payload: {
  lat: number; lng: number; title: string; description?: string; photos?: string[];
}) {
  return http(`/points`, { method:'POST', body: JSON.stringify(payload) });
}

/** Создать улов */
export async function addCatch(payload: {
  lat: number; lng: number; species?: string; length?: number; weight?: number;
  method?: string; bait?: string; gear?: string; caption?: string; photo_url?: string;
  caught_at?: string; privacy?: 'all'|'friends'|'private';
}) {
  return http(`/catch`, { method:'POST', body: JSON.stringify(payload) });
}

/** Избранные погодные точки (храним на бек/или локально — фронт прозрачен) */
export async function getWeatherFavs() {
  try {
    return await http<{ id:string; lat:number; lng:number; name:string }[]>(`/weather/favs`);
  } catch (e:any) {
    // fallback на localStorage, если ендпоинта нет
    const raw = localStorage.getItem('weather_favs') || '[]';
    return JSON.parse(raw);
  }
}
export async function saveWeatherFav(fav: { id?:string; lat:number; lng:number; name:string }) {
  try {
    return await http(`/weather/favs`, { method:'POST', body: JSON.stringify(fav) });
  } catch (e:any) {
    const list = await getWeatherFavs();
    const withId = { ...fav, id: fav.id || String(Date.now()) };
    const next = [withId, ...list.filter((x:any)=>x.id!==withId.id)];
    localStorage.setItem('weather_favs', JSON.stringify(next));
    return withId;
  }
}

/** Техническая проверка доступности API */
export async function ping() {
  try {
    // если есть /health — отлично, иначе быстрая заглушка к /feed с нулевыми лимитами
    const res = await http(`/health`).catch(() => http(`/feed?limit=1&offset=0`));
    return { ok: true, res };
  } catch (e:any) {
    return { ok: false, error: e?.message || String(e) };
  }
}

export default {
  feed,
  points,
  getProfile,
  getNotifications,
  getCatchById,
  addComment,
  addPlace,
  addCatch,
  getWeatherFavs,
  saveWeatherFav,
  ping,
};
