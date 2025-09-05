#!/bin/bash
set -euo pipefail

SRC="src"
COMP="$SRC/components"
PAGES="$SRC/pages"
STYLES="$SRC/styles"

mkdir -p "$SRC" "$COMP" "$PAGES" "$STYLES"

# ====== main.tsx ======
cat > "$SRC/main.tsx" <<'TSX'
import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import "./styles/app.css";

declare global {
  interface Window { API_BASE?: string }
}

// Позволяет при деплое переопределить базу API из <script>.
if (!window.API_BASE) {
  window.API_BASE = (location.protocol + "//" + location.host + "/api/v1");
}

const el = document.getElementById("root")!;
createRoot(el).render(
  <React.StrictMode>
    <BrowserRouter>
      <App/>
    </BrowserRouter>
  </React.StrictMode>
);
TSX

# ====== api.ts ======
cat > "$SRC/api.ts" <<'TS'
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
TS

# ====== types.ts ======
cat > "$SRC/types.ts" <<'TS'
export type LatLng = { lat:number; lng:number };

export type Point = {
  id: number|string;
  name?: string;
  type?: "spot"|"catch"|"shop"|"base"|string;
  lat: number;
  lng: number;
  photos?: string[];
  description?: string;
};

export type FeedItem = {
  id: number;
  user_id: number;
  user_name?: string;
  user_avatar?: string;
  lat?: number;
  lng?: number;
  species?: string;
  length?: number|string;
  weight?: number|string;
  method?: string;
  bait?: string;
  gear?: string;
  caption?: string;
  media_url?: string;
  created_at?: string;
  likes_count?: number;
  comments_count?: number;
  liked_by_me?: 0|1|boolean;
};

export type CatchRecord = FeedItem & {
  media_urls?: string[];
  weather?: any;
  privacy?: "all"|"friends"|"private";
  caught_at?: string;
};

export type NotificationItem = {
  id: number;
  title: string;
  body?: string;
  link?: string;
  created_at?: string;
  read?: boolean;
};

export type ProfileMe = {
  id: number;
  name: string;
  avatar?: string;
  photo_url?: string;
  email?: string;
  stats?: { catches?: number; friends?: number; points?: number };
};
TS

# ====== App.tsx ======
cat > "$SRC/App.tsx" <<'TSX'
import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import Header from "./components/Header";
import BottomNav from "./components/BottomNav";

import FeedScreen from "./pages/FeedScreen";
import MapScreen from "./pages/MapScreen";
import CatchDetailPage from "./pages/CatchDetailPage";
import AddCatchPage from "./pages/AddCatchPage";
import AddPlacePage from "./pages/AddPlacePage";
import NotificationsPage from "./pages/NotificationsPage";
import ProfilePage from "./pages/ProfilePage";
import WeatherPage from "./pages/WeatherPage";
import PlaceDetailPage from "./pages/PlaceDetailPage";

export default function App(){
  // points в хедере можно подтянуть из профиля, здесь заглушка
  const [points] = React.useState<number>(0);

  return (
    <div className="app">
      <Header points={points}/>
      <Routes>
        <Route path="/" element={<Navigate to="/map" replace/>} />
        <Route path="/map" element={<MapScreen/>} />
        <Route path="/feed" element={<FeedScreen/>} />
        <Route path="/catch/:id" element={<CatchDetailPage/>} />
        <Route path="/add-catch" element={<AddCatchPage/>} />
        <Route path="/add-place" element={<AddPlacePage/>} />
        <Route path="/alerts" element={<NotificationsPage/>} />
        <Route path="/profile" element={<ProfilePage/>} />
        <Route path="/weather" element={<WeatherPage/>} />
        <Route path="/place/:id" element={<PlaceDetailPage/>} />
        {/* запасной роут */}
        <Route path="*" element={<Navigate to="/map" replace/>}/>
      </Routes>
      <BottomNav/>
    </div>
  );
}
TSX

echo "✅ Core файлы записаны: App.tsx, main.tsx, api.ts, types.ts"
echo "ℹ️ Проверь, что у тебя уже есть остальные страницы и компоненты из предыдущего шага."