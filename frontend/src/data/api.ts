const BASE = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";

async function http<T=any>(path: string, init?: RequestInit): Promise<T>{
  const r = await fetch(`${BASE}${path}`, { credentials: "include", ...init });
  if(!r.ok) throw new Error(String(r.status));
  return r.json();
}

export const api = {
  // карта/точки
  points: (params:string)=> http(`/map/points${params}`),
  placeById: (id:number|string)=> http(`/map/points/${id}`),
  addPlace: (payload:any)=> http(`/points`, { method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify(payload) }),

  // лента/уловы
  feed: (params:string)=> http(`/feed${params}`),
  catchById: (id:number|string)=> http(`/catch/${id}`),
  addCatch: (payload:any)=> http(`/catches`, { method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify(payload) }),
  addComment: (id:number|string, body:string)=> http(`/catch/${id}/comments`, { method:"POST", headers:{ "Content-Type":"application/json" }, body: JSON.stringify({ body }) }),
  toggleLike: (id:number|string)=> http(`/catch/${id}/like`, { method:"POST" }),

  // медиа/погода
  upload: (form:FormData)=> fetch(`${BASE}/upload`, { method:"POST", body: form, credentials:"include" }).then(r=>{ if(!r.ok) throw new Error(String(r.status)); return r.json(); }),
  weather: (lat:number, lng:number, dt?:number)=> http(`/weather?lat=${lat}&lng=${lng}${dt?`&dt=${dt}`:''}`),

  // профиль/друзья/рейтинги/уведомления
  me: ()=> http(`/profile/me`),
  friends: ()=> http(`/friends`),
  ratings: ()=> http(`/ratings`),
  notifications: ()=> http(`/notifications`),
};

export default api;
