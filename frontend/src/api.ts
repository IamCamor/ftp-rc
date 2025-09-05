import { CONFIG } from "./config";

const BASE = CONFIG.apiBase;

/** Нормализует произвольный ответ (массив/объект) к массиву элементов */
function normalizeArray(payload: any): any[] {
  if (Array.isArray(payload)) return payload;
  if (payload == null) return [];
  // наиболее вероятные контейнеры
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.points)) return payload.points;
  // объект точек вида {id: {...}, ...}
  if (typeof payload === "object") {
    const vals = Object.values(payload);
    // если это массив элементов внутри одного ключа
    if (vals.length === 1 && Array.isArray(vals[0])) return vals[0] as any[];
  }
  console.warn("normalizeArray: неизвестный формат, возвращаю []", payload);
  return [];
}

async function request(path: string, options: RequestInit = {}) {
  const res = await fetch(BASE + path, {
    ...options,
    credentials: "include",
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
  feed: async (limit = 10, offset = 0) => {
    const payload = await request(`/feed?limit=${limit}&offset=${offset}`);
    return normalizeArray(payload);
  },

  // Карта/точки
  points: async (bbox?: [number, number, number, number], limit = 500, filter?: string) => {
    const params = new URLSearchParams();
    params.set("limit", String(limit));
    if (filter) params.set("filter", filter);
    if (bbox) params.set("bbox", bbox.join(","));
    const payload = await request(`/map/points?` + params.toString());
    return normalizeArray(payload);
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
