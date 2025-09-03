export interface CatchItem {
  id: number;
  user_id: number;
  user_name: string;
  user_avatar: string;
  lat: number;
  lng: number;
  species?: string;
  length?: number;
  weight?: number;
  depth?: number;
  method?: string;
  bait?: string;
  gear?: string;
  water_type?: string;
  water_temp?: number;
  wind_speed?: number;
  pressure?: number;
  companions?: string;
  caption?: string;
  media_url?: string;
  privacy: 'all'|'friends';
  caught_at?: string | null;
  created_at: string;
  likes_count: number;
  comments_count: number;
  liked_by_me: boolean;
}

export interface MapIcons {
  types: Record<string, string | { url: string; size?: [number,number]; anchor?: [number,number]; popup?: [number,number]; }>;
  default: string | { url: string; size?: [number,number]; anchor?: [number,number]; popup?: [number,number]; };
}

export interface MapPoint {
  id: number;
  type: string;
  lat: number;
  lng: number;
  title: string;
  descr?: string;
  highlight?: boolean;
  source: 'fishing_points'|'stores'|'events';
}

const API_BASE = import.meta.env.VITE_API_BASE ?? 'https://api.fishtrackpro.ru/api/v1';

async function http<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    credentials: 'include',
    headers: {
      ...(opts.headers ?? {}),
    },
    ...opts
  });
  if (!res.ok) {
    const text = await res.text().catch(()=>'');
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json();
}

export async function fetchFeed(limit=10, offset=0) {
  return http<CatchItem[]>(`/feed?limit=${limit}&offset=${offset}`);
}

export async function createCatch(form: FormData) {
  const res = await fetch(`${API_BASE}/catches`, {
    method: 'POST',
    body: form,
    credentials: 'include'
  });
  if (!res.ok) {
    const text = await res.text().catch(()=>'');
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json() as Promise<CatchItem>;
}

export async function fetchMapIcons() {
  return http<MapIcons>('/map/icons');
}

export async function fetchMapPoints(limit=2000, offset=0) {
  return http<{items: MapPoint[]}>(`/map/points?limit=${limit}&offset=${offset}`);
}
