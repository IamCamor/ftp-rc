// src/api.ts
export const API_BASE = (window as any).__API__ || "https://api.fishtrackpro.ru";

async function http<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const url = `${API_BASE}${path}`;
  const res = await fetch(url, {
    credentials: "include",
    headers: { "Accept": "application/json", ...(opts.headers || {}) },
    ...opts,
  });
  if (!res.ok) {
    let msg = `${res.status}`;
    try {
      const j = await res.json();
      msg = j.message || JSON.stringify(j);
    } catch {}
    throw new Error(msg);
  }
  return res.json();
}

export type BBox = [number, number, number, number];

export const api = {
  // Map points
  points: (p: { filter?: string; bbox?: BBox; limit?: number } = {}) => {
    const params = new URLSearchParams();
    if (p.limit) params.set("limit", String(p.limit));
    if (p.filter) params.set("filter", p.filter);
    if (p.bbox) params.set("bbox", p.bbox.join(","));
    return http<{ items: any[] }>(`/api/v1/map/points?${params}`);
  },

  // Feed
  feed: (p: { limit?: number; offset?: number } = {}) => {
    const params = new URLSearchParams();
    if (p.limit) params.set("limit", String(p.limit));
    if (p.offset) params.set("offset", String(p.offset));
    return http<{ items: any[]; nextOffset?: number }>(`/api/v1/feed?${params}`);
  },
  catchById: (id: number|string) =>
    http<any>(`/api/v1/catch/${id}`),

  // Uploads
  upload: async (files: File[]) => {
    const fd = new FormData();
    files.forEach((f) => fd.append("files[]", f));
    return http<{ items: { url: string }[] }>(`/api/v1/upload`, {
      method: "POST",
      body: fd,
    });
  },

  // Catches
  addCatch: (payload: any) =>
    http<any>(`/api/v1/catches`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    }),

  // Places
  addPlace: (payload: any) =>
    http<any>(`/api/v1/points`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    }),

  // Weather (non-blocking)
  weather: async (lat: number, lng: number, dt?: number) => {
    try {
      const params = new URLSearchParams({ lat: String(lat), lng: String(lng) });
      if (dt) params.set("dt", String(dt));
      return await http<any>(`/api/v1/weather?${params}`);
    } catch (e) {
      return { source: "openweather", error: "unavailable" };
    }
  },

  // Social
  likeCatch: (id: number|string) =>
    http<{ ok: boolean }>(`/api/v1/catch/${id}/like`, { method: "POST" }),
  addComment: (id: number|string, text: string) =>
    http<{ ok: boolean }>(`/api/v1/catch/${id}/comments`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text }),
    }),
  follow: (userId: number|string) =>
    http<{ ok: boolean }>(`/api/v1/follow/${userId}`, { method: "POST" }),
};
