import { CONFIG } from "./config";

const BASE = CONFIG.apiBase;

async function request(path: string, options: RequestInit = {}) {
  const res = await fetch(BASE + path, {
    ...options,
    credentials: "include", // чтобы работали cookie с CORS
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    },
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`API ${res.status}: ${text || res.statusText}`);
  }
  const ct = res.headers.get("content-type") || "";
  return ct.includes("application/json") ? res.json() : res.text();
}

export const API = {
  // Лента
  feed: (limit = 10, offset = 0) =>
    request(`/feed?limit=${limit}&offset=${offset}`),

  // Карта/точки (по bbox: [minLng,minLat,maxLng,maxLat])
  points: (bbox?: [number, number, number, number], limit = 500, filter?: string) => {
    const params = new URLSearchParams();
    params.set("limit", String(limit));
    if (filter) params.set("filter", filter);
    if (bbox) params.set("bbox", bbox.join(","));
    return request(`/map/points?` + params.toString());
  },

  // Улов
  catchById: (id: number) => request(`/catch/${id}`),
  addCatch: (data: any) => request(`/catches`, { method: "POST", body: JSON.stringify(data) }),

  // Места
  addPlace: (data: any) => request(`/points`, { method: "POST", body: JSON.stringify(data) }),

  // Уведомления/профиль/погода
  notifications: () => request(`/notifications`),
  profile: () => request(`/profile/me`),
  weather: (lat: number, lng: number, dt?: number) =>
    request(`/weather?lat=${lat}&lng=${lng}` + (dt ? `&dt=${dt}` : "")),
};
