export const API_BASE = 'https://api.fishtrackpro.ru/api/v1';

type Method = 'GET'|'POST'|'PUT'|'PATCH'|'DELETE';

async function http<T>(
  path: string,
  { method='GET', body, auth=false, query }: { method?: Method; body?: any; auth?: boolean; query?: Record<string, any> } = {}
): Promise<T> {
  const url = new URL(API_BASE + path);
  if (query) {
    Object.entries(query).forEach(([k,v])=>{
      if (v !== undefined && v !== null) url.searchParams.set(k, String(v));
    });
  }

  // Публичные: без cookie → проще CORS
  // Приватные: с cookie (Sanctum/сессия)
  const fetchOpts: RequestInit = {
    method,
    mode: 'cors',
    credentials: auth ? 'include' : 'omit',
    headers: {
      ...(body instanceof FormData ? {} : {'Content-Type':'application/json'})
    },
    body: body ? (body instanceof FormData ? body : JSON.stringify(body)) : undefined
  };

  const res = await fetch(url.toString(), fetchOpts);
  if (!res.ok) {
    const txt = await res.text().catch(()=> '');
    throw new Error(`${res.status} ${res.statusText} :: ${txt.slice(0,400)}`);
  }
  // На /notifications может быть 204
  if (res.status === 204) return {} as T;
  const ct = res.headers.get('content-type') || '';
  if (ct.includes('application/json')) return res.json() as Promise<T>;
  return (await res.text()) as unknown as T;
}

/* ==== Публичные ==== */
export const api = {
  feed: (params: {limit?:number; offset?:number; sort?:'new'|'top'; fish?:string; near?:string}={}) =>
    http('/feed', { query: params }),

  points: (params: {limit?:number; bbox?:string; filter?:string}={}) =>
    http('/map/points', { query: params }),

  catchById: (id: number|string) =>
    http(`/catch/${id}`),

  weather: (params: {lat:number; lng:number; dt?:number}) =>
    http('/weather', { query: params }),

  addCatch: (payload: any) =>
    http('/catches', { method: 'POST', body: payload }), // публичная публикация допускается гостем, если бек так настроен

  addPlace: (payload: any) =>
    http('/points', { method: 'POST', body: payload }),

  /* ==== Приватные (cookies required) ==== */
  me: () => http('/profile/me', { auth:true }),
  notifications: () => http('/notifications', { auth:true }),
  followToggle: (userId: number|string) => http(`/follow/${userId}`, { method: 'POST', auth:true }),
  likeToggle: (catchId: number|string) => http(`/catch/${catchId}/like`, { method: 'POST', auth:true }),
  addComment: (catchId: number|string, payload: {text:string}) => http(`/catch/${catchId}/comments`, { method:'POST', body: payload, auth:true }),
};
