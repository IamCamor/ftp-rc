export const API_BASE = (window as any).__API__ || 'https://api.fishtrackpro.ru/api/v1';

async function req(path: string, init?: RequestInit) {
  const res = await fetch(`${API_BASE}${path}`, {
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' , ...(init?.headers||{}) },
    ...init
  });
  if (!res.ok) {
    let p = null; try { p = await res.text(); } catch {}
    console.error('HTTP', res.status, path, p);
    throw new Error(String(res.status));
  }
  const ct = res.headers.get('content-type')||'';
  return ct.includes('application/json') ? res.json() : res.text();
}

export const api = {
  points: (params: {limit?:number; filter?:string; bbox?: string}) => {
    const q = new URLSearchParams();
    if (params.limit) q.set('limit', String(params.limit));
    if (params.filter) q.set('filter', params.filter);
    if (params.bbox) q.set('bbox', params.bbox);
    return req(`/map/points?${q.toString()}`);
  },
  feed: (params: {limit?:number; offset?:number}) => {
    const q = new URLSearchParams();
    if (params.limit!=null) q.set('limit', String(params.limit));
    if (params.offset!=null) q.set('offset', String(params.offset));
    return req(`/feed?${q.toString()}`);
  },
  catchById: (id:number) => req(`/catch/${id}`),
  addComment: (id:number, text:string, parent_id?:number|null) =>
    req(`/catch/${id}/comments`, { method:'POST', body: JSON.stringify({ text, parent_id: parent_id ?? null }) }),

  weather: (lat:number,lng:number, dt?:number) => {
    const q = new URLSearchParams({ lat:String(lat), lng:String(lng) });
    if (dt) q.set('dt', String(dt));
    return req(`/weather?${q.toString()}`);
  }
}
