import { API_BASE } from './config';

type Method = 'GET'|'POST'|'PUT'|'PATCH'|'DELETE';
type Q = Record<string, string|number|boolean|undefined|null>;

async function http<T>(path:string, {method='GET', body, auth=false, query}:{method?:Method; body?:any; auth?:boolean; query?:Q} = {}):Promise<T>{
  const url = new URL(API_BASE + path);
  if (query) Object.entries(query).forEach(([k,v])=>{
    if (v!==undefined && v!==null && v!=='') url.searchParams.set(k,String(v));
  });
  const opts: RequestInit = {
    method,
    mode:'cors',
    credentials: auth ? 'include' : 'omit',
    headers: body instanceof FormData ? {'Accept':'application/json'} : {'Content-Type':'application/json','Accept':'application/json'},
    body: body ? (body instanceof FormData ? body : JSON.stringify(body)) : undefined,
  };
  const res = await fetch(url.toString(), opts);
  if (!res.ok) {
    let msg = '';
    try { msg = JSON.stringify(await res.clone().json()); } catch { msg = await res.text(); }
    throw new Error(`${res.status} ${res.statusText} :: ${msg.slice(0,400)}`);
  }
  if (res.status===204) return {} as T;
  const ct = res.headers.get('content-type')||'';
  return ct.includes('application/json') ? res.json() : (await res.text() as unknown as T);
}

export const api = {
  // FEED / MAP (всегда через /v1)
  feed: (p:{limit?:number; offset?:number; sort?:'new'|'top'; fish?:string; near?:string}={}) => http('/v1/feed',{query:p}),
  points: (p:{limit?:number; bbox?:string; filter?:string}={}) => http('/v1/map/points',{query:p}),

  // DETAIL
  catchById: (id:number|string)=> http(`/v1/catch/${id}`),

  // WEATHER
  weather: (p:{lat:number; lng:number; dt?:number})=> http('/v1/weather',{query:p}),

  // MUTATIONS
  addCatch: (payload:any)=> http('/v1/catches',{method:'POST', body:payload}),
  addPlace: (payload:any)=> http('/v1/points',{method:'POST', body:payload}),

  // PROFILE / ALERTS
  me: ()=> http('/v1/profile/me', {auth:true}),
  notifications: ()=> http('/v1/notifications', {auth:true}),

  // SOCIAL
  likeToggle: (id:number|string)=> http(`/v1/catch/${id}/like`, {method:'POST', auth:true}),
  addComment: (id:number|string, payload:{text:string})=> http(`/v1/catch/${id}/comments`, {method:'POST', body:payload, auth:true}),
  followToggle: (userId:number|string)=> http(`/v1/follow/${userId}`, {method:'POST', auth:true}),
};

export default api;

// совместимость для старых импортов { points }
export const points = (p:{limit?:number; bbox?:string; filter?:string}={}) => api.points(p);

// локальные «избранные локации погоды»
const WEATHER_KEY = 'weather_favs';
export type WeatherFav = { id: string; name: string; lat: number; lng: number };
export const getWeatherFavs = ():WeatherFav[] => {
  try { const v = localStorage.getItem(WEATHER_KEY); const arr = v? JSON.parse(v): []; return Array.isArray(arr)?arr:[]; } catch { return []; }
};
export const saveWeatherFav = (fav:WeatherFav) => {
  const list = getWeatherFavs();
  const i = list.findIndex(x=>x.id===fav.id);
  if (i>=0) list[i]=fav; else list.push(fav);
  localStorage.setItem(WEATHER_KEY, JSON.stringify(list));
  return list;
};
