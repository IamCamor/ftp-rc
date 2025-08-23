// frontend/src/api/feed.ts
const API_BASE = import.meta.env.VITE_API_BASE?.replace(/\/+$/,'') || '/api';

export type FeedScope = 'global'|'local'|'follow';

export interface FeedItem {
  id: number;
  user_id: number|null;
  user_name?: string|null;
  user_avatar?: string|null;
  lat?: number|null;
  lng?: number|null;
  species?: string|null;
  size_cm?: number|null;
  weight_g?: number|null;
  method?: string|null;
  gear?: string|null;
  bait?: string|null;
  caption?: string|null;
  media_url?: string|null;
  created_at?: string|null;
  likes_count: number;
  comments_count: number;
  liked_by_me: 0|1|boolean;
}

export async function fetchFeed(params: {
  scope?: FeedScope; lat?: number; lng?: number; radius_km?: number;
  page?: number; per?: number;
} = {}) {
  const {scope='global', lat, lng, radius_km=50, page=1, per=20} = params;
  const q = new URLSearchParams({ scope, page: String(page), per: String(per) });
  if (scope==='local' && lat!=null && lng!=null) {
    q.set('lat', String(lat)); q.set('lng', String(lng)); q.set('radius_km', String(radius_km));
  }
  const res = await fetch(`${API_BASE}/v1/feed?${q.toString()}`, { credentials: 'include' });
  if (!res.ok) throw new Error(`Feed HTTP ${res.status}`);
  return res.json() as Promise<{items:FeedItem[], meta:any}>;
}

export async function getComments(catchId: number) {
  const res = await fetch(`${API_BASE}/v1/feed/${catchId}/comments`, { credentials: 'include' });
  if (!res.ok) throw new Error(`Comments HTTP ${res.status}`);
  return res.json() as Promise<{items: Array<{id:number, body:string, user_name?:string|null, user_avatar?:string|null, created_at?:string}>}>;
}

export async function like(catchId: number) {
  const res = await fetch(`${API_BASE}/v1/feed/${catchId}/like`, { method: 'POST', credentials: 'include' });
  if (!res.ok) throw new Error(`Like HTTP ${res.status}`);
  return res.json();
}

export async function unlike(catchId: number) {
  const res = await fetch(`${API_BASE}/v1/feed/${catchId}/like`, { method: 'DELETE', credentials: 'include' });
  if (!res.ok) throw new Error(`Unlike HTTP ${res.status}`);
  return res.json();
}

export async function addComment(catchId: number, body: string) {
  const res = await fetch(`${API_BASE}/v1/feed/${catchId}/comments`, {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
    body: JSON.stringify({body}),
    credentials: 'include'
  });
  if (!res.ok) throw new Error(`AddComment HTTP ${res.status}`);
  return res.json();
}