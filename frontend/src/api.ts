import config from './config';

/** Базовый fetch с токеном и JSON */
async function request<T=any>(
  url: string,
  opts: RequestInit & { auth?: boolean; json?: boolean } = {}
): Promise<T> {
  const headers: Record<string,string> = {};
  const isJson = opts.json !== false; // по умолчанию JSON
  if (isJson) headers['Content-Type'] = 'application/json';

  if (opts.auth !== false) {
    const token = localStorage.getItem('token');
    if (token) headers['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(url, {
    ...opts,
    headers: { ...headers, ...(opts.headers||{}) },
    body: (isJson && typeof opts.body === 'object' && opts.body !== null)
      ? JSON.stringify(opts.body)
      : (opts.body as any),
    credentials: 'include', // чтобы куки работали, если надо
  });

  const ct = res.headers.get('content-type') || '';
  const isJsonResp = ct.includes('application/json');

  if (!res.ok) {
    const msg = isJsonResp ? ((await res.json()) as any)?.message : await res.text();
    throw new Error(msg || `HTTP ${res.status}`);
  }
  return (isJsonResp ? res.json() : (res.text() as any)) as Promise<T>;
}

const base = config.apiBase; // обычно https://api.fishtrackpro.ru/api/v1

/** Формат даты в MySQL DATETIME */
function toSqlDatetime(d: Date | string | number): string {
  const date = d instanceof Date ? d : new Date(d);
  const pad = (n:number)=> String(n).padStart(2,'0');
  const Y = date.getFullYear();
  const M = pad(date.getMonth()+1);
  const D = pad(date.getDate());
  const h = pad(date.getHours());
  const m = pad(date.getMinutes());
  const s = pad(date.getSeconds());
  return `${Y}-${M}-${D} ${h}:${m}:${s}`;
}

/* ======================= ПУБЛИЧНЫЕ API ======================= */

// Лента
export async function feed(limit=10, offset=0){
  return request(`${base}/feed?limit=${limit}&offset=${offset}`, { method:'GET' });
}

// Карта: точки
export async function points(params: {limit?:number; bbox?: string} = {}){
  const q = new URLSearchParams();
  if (params.limit != null) q.set('limit', String(params.limit));
  if (params.bbox) q.set('bbox', params.bbox);
  return request(`${base}/map/points?${q.toString()}`, { method:'GET' });
}

// Карточка улова
export async function catchById(id: string|number){
  return request(`${base}/catch/${id}`, { method:'GET' });
}

// Комментарий к улову
export async function addCatchComment(id: string|number, text: string){
  return request(`${base}/catch/${id}/comments`, { method:'POST', body:{ text } });
}

// Лайк/оценка/бонус (если эндпоинтов нет — вернётся 404, мы его не пробрасываем)
export async function likeCatch(id: string|number){
  try { return await request(`${base}/catch/${id}/like`, { method:'POST' }); }
  catch(e){ return { ok:false, error: (e as Error).message }; }
}
export async function rateCatch(id: string|number, stars:number){
  try { return await request(`${base}/catch/${id}/rate`, { method:'POST', body:{ stars } }); }
  catch(e){ return { ok:false, error: (e as Error).message }; }
}
export async function bonusAward(action: string, meta?: any){
  try { return await request(`${base}/bonus/award`, { method:'POST', body:{ action, meta } }); }
  catch(e){ return { ok:false, error: (e as Error).message }; }
}

// Профиль
export async function profileMe(){
  return request(`${base}/profile/me`, { method:'GET' });
}
export function isAuthed(): boolean {
  return Boolean(localStorage.getItem('token'));
}
export async function logout(){
  try { await request(`${base}/auth/logout`, { method:'POST' }); } catch {}
  localStorage.removeItem('token');
  return { ok:true };
}

// Регистрация/Логин (парольная форма под фича-флаг)
export async function register(payload: {
  email: string; password: string; name?: string; agreePersonal?: boolean; agreeOffer?: boolean; agreeRules?: boolean;
}){
  return request(`${base}/auth/register`, { method:'POST', body: payload, auth:false });
}
export async function login(email: string, password: string){
  const r = await request<{token?:string}>(`${base}/auth/login`, {
    method:'POST', body:{ email, password }, auth:false
  });
  if (r?.token) localStorage.setItem('token', r.token);
  return r;
}

// OAuth провайдеры (редиректим на API-роуты вне /api/v1)
function apiOriginFromBase(): string {
  try {
    const u = new URL(base);
    // урезаем /api/v1
    const path = u.pathname.replace(/\/api\/v1\/?$/,'') || '/';
    return `${u.protocol}//${u.host}${path}`.replace(/\/+$/,'');
  } catch {
    return 'https://api.fishtrackpro.ru';
  }
}
export function buildOAuthUrl(provider: 'google'|'vk'|'yandex'|'apple'){
  const origin = apiOriginFromBase();
  return `${origin}/auth/${provider}/redirect`;
}

// Погода — избранные точки
export async function getWeatherFavs(){
  return request(`${base}/weather/favs`, { method:'GET' });
}
export async function saveWeatherFav(p: {lat:number; lng:number; label?:string}){
  return request(`${base}/weather/favs`, { method:'POST', body:{
    lat: p.lat, lng: p.lng, label: p.label ?? ''
  }});
}

// Баннеры
export async function bannersGet(slot: string){
  const q = new URLSearchParams({ slot });
  return request(`${base}/banners?${q.toString()}`, { method:'GET' });
}

// Добавление улова (минимальная форма JSON; если нужен multipart — можно расширить)
export type AddCatchPayload = {
  lat: number; lng: number;
  species?: string;
  length?: number; weight?: number;
  style?: string; lure?: string; tackle?: string;
  notes?: string;
  caught_at?: string | Date | number; // конвертим в SQL
  photo_url?: string; // ссылка, если уже загружено
  privacy?: 'all'|'friends'|'me';
};
export async function addCatch(payload: AddCatchPayload){
  const body = { ...payload } as any;
  if (body.caught_at) body.caught_at = toSqlDatetime(body.caught_at);
  return request(`${base}/catch`, { method:'POST', body });
}

// Общий «тонкий» экспорт для точечных вызовов
export const api = { request, base };

export default {
  request, base,
  // контент
  feed, points,
  catchById, addCatchComment,
  likeCatch, rateCatch, bonusAward,
  // профиль/авторизация
  profileMe, isAuthed, logout, register, login,
  buildOAuthUrl,
  // погода
  getWeatherFavs, saveWeatherFav,
  // баннеры
  bannersGet,
  // формы
  addCatch,
  // вспомогательное
  api,
};
