import { CONFIG } from "./config";
import type { Point, FeedItem, CatchRecord, NotificationItem, ProfileMe } from "./types";

/** универсальный fetch с «мягкой» обработкой бэков, которые могут отдавать {items} или голый массив */
async function m3(path: string, init?: RequestInit) {
  const url = path.startsWith("http") ? path : `${CONFIG.apiBase}${path}`;
  const res = await fetch(url, {
    credentials: "include",
    headers: { "Accept": "application/json", ...(init?.headers||{}) },
    ...init,
  });
  if (!res.ok) {
    // попытка graceful fallback: если вдруг фронт смотрит на /api/v1, а бэк на /api
    if (res.status === 404 && url.includes("/api/v1/")) {
      const alt = url.replace("/api/v1/", "/api/");
      const res2 = await fetch(alt, { credentials: "include", headers: { "Accept":"application/json" }, ...init });
      if (!res2.ok) throw new Error(`${res2.status}`);
      try { return await res2.json(); } catch { return null; }
    }
    throw new Error(`${res.status}`);
  }
  try { return await res.json(); } catch { return null; }
}

function asArray<T=any>(data: any): T[] {
  if (Array.isArray(data)) return data as T[];
  if (Array.isArray(data?.items)) return data.items as T[];
  if (Array.isArray(data?.data)) return data.data as T[];
  return [];
}

export const API = {
  // Карта: точки
  async points(params: {limit?:number; bbox?:string; filter?:string} = {}): Promise<Point[]> {
    const q = new URLSearchParams();
    if (params.limit) q.set("limit", String(params.limit));
    if (params.bbox)  q.set("bbox", params.bbox);
    if (params.filter) q.set("filter", params.filter);
    const data = await m3(`/map/points${q.toString() ? `?${q}` : ""}`);
    return asArray<Point>(data);
  },

  async pointById(id: string|number): Promise<Point|null> {
    const data = await m3(`/map/points/${id}`);
    // Бэки могут вернуть {id, ...} или {data:{...}}
    return data?.id ? data : (data?.data?.id ? data.data : data);
  },

  // Лента
  async feed(limit=10, offset=0): Promise<FeedItem[]> {
    const qs = new URLSearchParams({ limit: String(limit), offset: String(offset) });
    const data = await m3(`/feed?${qs}`);
    return asArray<FeedItem>(data);
  },

  // Уловы
  async catchById(id: number|string): Promise<CatchRecord|null> {
    const data = await m3(`/catch/${id}`);
    return data?.id ? data : (data?.data?.id ? data.data : data);
  },

  async addCatch(payload: Record<string,any>) {
    return m3(`/catches`, {
      method: "POST",
      body: JSON.stringify(payload),
      headers: { "Content-Type":"application/json" }
    });
  },

  // Точки
  async addPlace(payload: Record<string,any>) {
    return m3(`/points`, {
      method: "POST",
      body: JSON.stringify(payload),
      headers: { "Content-Type":"application/json" }
    });
  },

  // Погода (не блокирует UX)
  async weather(lat:number, lng:number, dt?:number) {
    const qs = new URLSearchParams({ lat:String(lat), lng:String(lng) });
    if (dt) qs.set("dt", String(dt));
    // Бэкенд-прокси /weather → {temp, wind, pressure, source} | raw openweather
    try { return await m3(`/weather?${qs}`); }
    catch { return null; }
  },

  // Уведомления
  async notifications(): Promise<NotificationItem[]> {
    const data = await m3(`/notifications`).catch(()=>null);
    return asArray<NotificationItem>(data);
  },

  // Профиль
  async profile(): Promise<ProfileMe|null> {
    const data = await m3(`/profile/me`).catch(()=>null);
    if (!data) return null;
    return data?.id ? data : (data?.data?.id ? data.data : data);
  }
};
