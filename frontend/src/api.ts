import config from './config';

/** ====== helpers ====== */
type HttpOpts = {
  method?: 'GET'|'POST'|'PUT'|'PATCH'|'DELETE';
  body?: any;
  headers?: Record<string,string>;
  auth?: boolean;           // добавлять Bearer токен
  credentials?: RequestCredentials; // по умолчанию 'omit'
};

function getToken(): string | null {
  try { return localStorage.getItem('token'); } catch { return null; }
}

function setToken(token?: string) {
  try {
    if (token) localStorage.setItem('token', token);
  } catch {}
}

export function logout() {
  try { localStorage.removeItem('token'); } catch {}
}

async function http<T=any>(url: string, opts: HttpOpts = {}): Promise<T> {
  const {
    method = 'GET',
    body,
    headers = {},
    auth = true,
    credentials = 'omit'
  } = opts;

  const token = getToken();

  const res = await fetch(url, {
    method,
    credentials,
    headers: {
      'Accept': 'application/json',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(auth && token ? { 'Authorization': `Bearer ${token}` } : {}),
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  // читаем как текст, затем пытаемся JSON
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

/** ====== bases ====== */
const base = config.apiBase;     // например: https://api.fishtrackpro.ru/api/v1
const authBase = config.authBase; // например: https://api.fishtrackpro.ru

/** ====== AUTH на authBase ====== */
export async function login(email: string, password: string) {
  const r = await http<{ token?: string; [k:string]: any }>(
    `${authBase}/auth/login`,
    { method:'POST', body:{ email, password }, auth:false }
  );
  if (r?.token) setToken(r.token);
  return r;
}

export async function register(
  name: string,
  email: string,
  password: string,
  username?: string,
  avatarUrl?: string
) {
  const body: any = { name, email, password };
  if (username) body.username = username;
  if (avatarUrl) body.photo_url = avatarUrl;

  const r = await http<{ token?: string; [k:string]: any }>(
    `${authBase}/auth/register`,
    { method:'POST', body, auth:false }
  );
  if (r?.token) setToken(r.token);
  return r;
}

export function oauthStart(provider: 'google'|'vk'|'yandex'|'apple') {
  // редиректим на backend-роут/oauth-провайдера
  window.location.href = `${authBase}/auth/${provider}/redirect`;
}

export function isAuthed() {
  return !!getToken();
}

/** ====== API на apiBase (/api/v1/...) ====== */

// лента
export async function feed(limit=10, offset=0) {
  return http(`${base}/feed?limit=${limit}&offset=${offset}`, { method:'GET' });
}

// карта: точки
export type BBox = { west:number; south:number; east:number; north:number };
export async function points(limit=500, bbox?: BBox) {
  const params = new URLSearchParams();
  params.set('limit', String(limit));
  if (bbox) {
    params.set('bbox', `${bbox.west},${bbox.south},${bbox.east},${bbox.north}`);
  }
  return http(`${base}/map/points?${params.toString()}`, { method:'GET' });
}

// детали улова
export async function catchById(id: number|string) {
  return http(`${base}/catch/${id}`, { method:'GET' });
}

// комментарий к улову
export async function addComment(catchId: number|string, text: string) {
  return http(`${base}/catch/${catchId}/comments`, { method:'POST', body:{ text } });
}

// профиль
export async function profileMe() {
  return http(`${base}/profile/me`, { method:'GET' });
}

// уведомления
export async function notifications() {
  return http(`${base}/notifications`, { method:'GET' });
}

// сохранение избранной точки для погоды (только для авторизованных)
export async function saveWeatherFav(lat: number, lng: number, label?: string) {
  if (config.auth?.requireAuthForWeatherSave && !isAuthed()) {
    const err: any = new Error('Требуется авторизация для сохранения точки погоды');
    err.code = 'AUTH_REQUIRED';
    throw err;
  }
  return http(`${base}/weather/favs`, { method:'POST', body:{ lat, lng, label } });
}

// получить избранные точки погоды
export async function getWeatherFavs() {
  return http(`${base}/weather/favs`, { method:'GET' });
}

// добавление улова (минимально)
export async function addCatch(payload: {
  lat:number; lng:number; species?:string; length?:number; weight?:number;
  method?:string; bait?:string; gear?:string; caption?:string; photo_url?:string; caught_at?:string;
}) {
  return http(`${base}/catch`, { method:'POST', body: payload });
}

// добавление места (минимально)
export async function addPlace(payload: {
  lat:number; lng:number; title:string; description?:string; photos?:string[];
}) {
  return http(`${base}/map/places`, { method:'POST', body: payload });
}
