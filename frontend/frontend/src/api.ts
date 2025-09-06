import { API_BASE } from './config';

type Method = 'GET'|'POST'|'PUT'|'PATCH'|'DELETE';

async function http<T>(
  path: string,
  { method='GET', body, auth=false, query }: { method?: Method; body?: any; auth?: boolean; query?: Record<string, any> } = {}
): Promise<T> {
  const url = new URL(API_BASE + path);
  if (query) {
    for (const [k,v] of Object.entries(query)) {
      if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, String(v));
    }
  }
  const opts: RequestInit = {
    method,
    mode: 'cors',
    credentials: auth ? 'include' : 'omit',
    headers: {
      ...(body instanceof FormData ? {} : {'Content-Type':'application/json'}),
      'Accept': 'application/json',
    },
    body: body ? (body instanceof FormData ? body : JSON.stringify(body)) : undefined,
  };
  const res = await fetch(url.toString(), opts);
  if (!res.ok) {
    let detail = '';
    try { detail = JSON.stringify(await res.clone().json()).slice(0,500); }
    catch { detail = (await res.text()).slice(0,500); }
    throw new Error(`${res.status} ${res.statusText} :: ${detail}`);
  }
  if (res.status === 204) return {} as T;
  const ct = res.headers.get('content-type') || '';
  return ct.includes('application/json') ? res.json() as Promise<T> : (await res.text() as unknown as T);
}

export const api = {
  feed: (params: {limit?:number; offset?:number; sort?:'new'|'top'; fish?:string; near?:string}={}) =>
    http('/v1/feed', { query: params }),

  points: (params: {limit?:number; bbox?:string; filter?:string}={}) =>
    http('/v1/map/points', { query: params }),

  catchById: (id: number|string) => http(`/v1/catch/${id}`),

  weather: (params: {lat:number; lng:number; dt?:number}) =>
    http('/v1/weather', { query: params }),

  addCatch: (payload: any) => http('/v1/catches', { method:'POST', body: payload }),
  addPlace: (payload: any) => http('/v1/points', { method:'POST', body: payload }),

  me: () => http('/profile/me', { auth:true }),
  notifications: () => http('/notifications', { auth:true }),
  likeToggle: (catchId: number|string) => http(`/v1/catch/${catchId}/like`, { method:'POST', auth:true }),
  addComment: (catchId: number|string, payload: {text:string}) => http(`/v1/catch/${catchId}/comments`, { method:'POST', body: payload, auth:true }),
  followToggle: (userId: number|string) => http(`/v1/follow/${userId}`, { method:'POST', auth:true }),
};

// default экспорт
export default api;

// Именованные – для совместимости там, где импортируют { points }
export const points = (params: {limit?:number; bbox?:string; filter?:string} = {}) => api.points(params);

// локальные «избранные локации погоды»
const WEATHER_KEY = 'weather_favs';
export type WeatherFav = { id: string; name: string; lat: number; lng: number };
export const getWeatherFavs = (): WeatherFav[] => {
  try { const v = localStorage.getItem(WEATHER_KEY); const arr = v? JSON.parse(v): []; return Array.isArray(arr)? arr: []; }
  catch { return []; }
};
export const saveWeatherFav = (fav: WeatherFav) => {
  const list = getWeatherFavs();
  const i = list.findIndex(x=>x.id===fav.id);
  if (i>=0) list[i]=fav; else list.push(fav);
  localStorage.setItem(WEATHER_KEY, JSON.stringify(list));
  return list;
};
