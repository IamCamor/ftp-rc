#!/usr/bin/env bash
set -euo pipefail

# Работает из корня фронта
ROOT="$(pwd)"
SRC="$ROOT/src"

mkdir -p "$SRC/screens" "$SRC/components" "$SRC/config" "$SRC/data" "$SRC/styles"

# ---------- 1) Универсальная иконка (если ещё нет) ----------
if [ ! -f "$SRC/components/Icon.tsx" ]; then
  cat > "$SRC/components/Icon.tsx" <<'TSX'
import React from "react";
import { ICONS } from "../config/ui";

type Props = {
  name: keyof typeof ICONS | string;
  className?: string;
  size?: number;
  weight?: number;
  grade?: number;
  fill?: 0|1;
  title?: string;
};

export default function Icon({ name, className="", size=24, weight=400, grade=0, fill=0, title }: Props){
  const glyph = (ICONS as any)[name] ?? name; // можно передать сырое имя
  return (
    <span
      className={`material-symbols-rounded ${className}`}
      style={{ fontSize: size, fontVariationSettings: `'FILL' ${fill}, 'wght' ${weight}, 'GRAD' ${grade}, 'opsz' ${Math.max(20, size)}` }}
      aria-label={title || (typeof name === "string" ? name : "")}
      title={title}
    >
      {glyph}
    </span>
  );
}
TSX
fi

# ---------- 2) Конфиг UI с иконками/логотипом (добавляем или обновляем) ----------
cat > "$SRC/config/ui.ts" <<'TS'
export const ASSETS = {
  logo: "/assets/logo.svg",
  defaultAvatar: "/assets/default-avatar.png",
  bgPattern: "/assets/bg-pattern.png",
};

export const ICONS = {
  map: "map",
  feed: "dynamic_feed",
  alerts: "notifications",
  profile: "account_circle",
  plus: "add",
  like: "favorite",
  comment: "mode_comment",
  share: "ios_share",
  back: "arrow_back",
  settings: "settings",
  friends: "group",
  rating: "military_tech",
  weather: "sunny",
  location: "location_on",
  edit: "edit",
  logout: "logout",
  check: "check",
  photo: "photo_camera",
  video: "videocam",
  place: "bookmark_added",
} as const;
TS

# ---------- 3) Стили для Material Symbols + слои ----------
cat > "$SRC/styles/ui.css" <<'CSS'
@import url('https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,GRAD,FILL@20..48,100..700,-50..200,0..1');

.material-symbols-rounded {
  font-family: 'Material Symbols Rounded';
  font-weight: normal; font-style: normal; font-size: 24px;
  line-height: 1; letter-spacing: normal; text-transform: none;
  display: inline-block; white-space: nowrap; word-wrap: normal;
  direction: ltr;
  -webkit-font-feature-settings: 'liga'; -webkit-font-smoothing: antialiased;
}

.z-header { z-index: 40; }
.z-fab { z-index: 35; }
.z-bottomnav { z-index: 30; }
.z-map-popover { z-index: 28; }
.z-map { z-index: 10; }
CSS

# ---------- 4) Страница уведомлений ----------
cat > "$SRC/screens/NotificationsPage.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";

type Noti = {
  id: number;
  type: string; // "like" | "comment" | "follow" | "system"
  title: string;
  body?: string;
  created_at: string;
  is_read?: boolean;
  link?: string;
};

async function fetchNotifications(): Promise<Noti[]> {
  try {
    const base = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
    const r = await fetch(`${base}/notifications`, { credentials: "include" });
    if (!r.ok) return [];
    const j = await r.json();
    return Array.isArray(j.items) ? j.items : [];
  } catch {
    return [];
  }
}

export default function NotificationsPage(){
  const [items, setItems] = useState<Noti[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(()=> {
    fetchNotifications().then((list)=> {
      setItems(list);
      setLoading(false);
    });
  },[]);

  if (loading) return <div className="p-4 text-gray-500">Загрузка…</div>;
  if (!items.length) return <div className="p-4 text-gray-500">Уведомлений пока нет</div>;

  const iconByType: Record<string,string> = {
    like: "like",
    comment: "comment",
    follow: "friends",
    system: "notifications",
  };

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="alerts" />
        <div className="font-semibold">Уведомления</div>
      </div>

      <ul className="divide-y divide-gray-100">
        {items.map(n => (
          <li key={n.id} className="p-3 flex gap-3 items-start">
            <Icon name={iconByType[n.type] || "notifications"} className={`${n.is_read ? "text-gray-400" : "text-blue-600"}`} />
            <div className="flex-1">
              <div className="font-medium">{n.title}</div>
              {n.body && <div className="text-gray-600 text-sm">{n.body}</div>}
              <div className="text-xs text-gray-400 mt-1">{new Date(n.created_at).toLocaleString()}</div>
            </div>
            {n.link && (
              <a href={n.link} className="text-sm text-blue-600 hover:underline">Открыть</a>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}
TSX

# ---------- 5) Страница профиля ----------
cat > "$SRC/screens/ProfilePage.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";
import { ASSETS } from "../config/ui";

type Profile = {
  id: number;
  name: string;
  handle?: string;
  avatar?: string;
  bonus?: number;
  catches_count?: number;
  friends_count?: number;
  followers_count?: number;
};

async function fetchMe(): Promise<Profile | null> {
  try {
    const base = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
    const r = await fetch(`${base}/profile/me`, { credentials: "include" });
    if (!r.ok) return null;
    const j = await r.json();
    return j?.data || j || null;
  } catch {
    return null;
  }
}

export default function ProfilePage(){
  const [me, setMe] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(()=> {
    fetchMe().then((p)=> { setMe(p); setLoading(false); });
  },[]);

  const avatar = me?.avatar || ASSETS.defaultAvatar;

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <img src={ASSETS.logo} alt="logo" className="w-6 h-6" />
          <div className="font-semibold">Профиль</div>
        </div>
        <a href="#/weather" className="flex items-center gap-1 text-sm">
          <Icon name="weather" /> Погода
        </a>
      </div>

      {loading ? (
        <div className="p-4 text-gray-500">Загрузка…</div>
      ) : me ? (
        <>
          <div className="p-4 flex items-center gap-3">
            <img src={avatar} alt="" className="w-16 h-16 rounded-full object-cover border border-white/40 shadow" />
            <div className="flex-1">
              <div className="font-semibold text-lg">{me.name}</div>
              <div className="text-gray-500 text-sm">@{me.handle || "user" + me.id}</div>
              <div className="mt-1 text-sm">
                <span className="inline-flex items-center gap-1 mr-3"><Icon name="rating" /> {me.bonus ?? 0}</span>
                <span className="inline-flex items-center gap-1 mr-3"><Icon name="place" /> {me.catches_count ?? 0}</span>
                <span className="inline-flex items-center gap-1"><Icon name="friends" /> {me.friends_count ?? 0}</span>
              </div>
            </div>
            <a href="#/settings" className="btn text-sm inline-flex items-center gap-1"><Icon name="settings" /> Настройки</a>
          </div>

          <div className="px-4 grid grid-cols-2 gap-3">
            <a href="#/my-catches" className="p-3 rounded-2xl bg-white/60 backdrop-blur border border-white/50 shadow-sm flex items-center gap-2">
              <Icon name="photo" /> Мои уловы
            </a>
            <a href="#/friends" className="p-3 rounded-2xl bg-white/60 backdrop-blur border border-white/50 shadow-sm flex items-center gap-2">
              <Icon name="friends" /> Друзья
            </a>
            <a href="#/ratings" className="p-3 rounded-2xl bg-white/60 backdrop-blur border border-white/50 shadow-sm flex items-center gap-2">
              <Icon name="rating" /> Рейтинги
            </a>
            <a href="#/logout" className="p-3 rounded-2xl bg-white/60 backdrop-blur border border-white/50 shadow-sm flex items-center gap-2">
              <Icon name="logout" /> Выйти
            </a>
          </div>
        </>
      ) : (
        <div className="p-4">
          <div className="rounded-2xl p-4 bg-white/60 backdrop-blur border border-white/50">
            <div className="font-semibold mb-1">Требуется вход</div>
            <div className="text-sm text-gray-600 mb-3">Войдите, чтобы видеть профиль и бонусы.</div>
            <a href="#/auth" className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-black text-white">
              <Icon name="login" /> Войти
            </a>
          </div>
        </div>
      )}
    </div>
  );
}
TSX

# ---------- 6) Обновляем/создаём BottomNav с вкладкой уведомлений ----------
cat > "$SRC/components/BottomNav.tsx" <<'TSX'
import React from "react";
import Icon from "./Icon";

type Tab = "map"|"feed"|"alerts"|"profile";

export default function BottomNav({ active, onChange, onFab }:{
  active: Tab;
  onChange: (t:Tab)=>void;
  onFab?: ()=>void;
}){
  const Item = ({id, label, icon}:{id:Tab; label:string; icon:string}) => (
    <button
      className={`flex flex-col items-center flex-1 py-2 ${active===id ? "text-black" : "text-gray-500"}`}
      onClick={()=>onChange(id)}
    >
      <Icon name={icon} />
      <span className="text-[11px] mt-0.5">{label}</span>
    </button>
  );
  return (
    <div className="z-bottomnav fixed bottom-0 left-0 right-0">
      <div className="mx-auto max-w-md relative">
        <div className="absolute left-0 right-0 bottom-8 flex justify-center pointer-events-none">
          <button
            className="pointer-events-auto rounded-full w-14 h-14 flex items-center justify-center shadow-lg bg-black text-white"
            onClick={onFab}
            aria-label="Добавить"
          >
            <Icon name="plus" />
          </button>
        </div>
        <div className="rounded-t-2xl backdrop-blur bg-white/70 border-t border-white/50 shadow flex">
          <Item id="map" label="Карта" icon="map" />
          <Item id="feed" label="Лента" icon="feed" />
          <div className="w-14" /> {/* место под FAB */}
          <Item id="alerts" label="Оповещения" icon="alerts" />
          <Item id="profile" label="Профиль" icon="profile" />
        </div>
      </div>
    </div>
  );
}
TSX

# ---------- 7) Подключаем страницы в App.tsx (хэш-навигация) ----------
cat > "$SRC/App.tsx" <<'TSX'
import React, { useEffect, useMemo, useState } from "react";
import MapScreen from "./screens/MapScreen";
import FeedScreen from "./screens/FeedScreen";
import NotificationsPage from "./screens/NotificationsPage";
import ProfilePage from "./screens/ProfilePage";
import BottomNav from "./components/BottomNav";

type Tab = "map"|"feed"|"alerts"|"profile";

function routeToTab(hash: string): Tab {
  const key = hash.replace(/^#\//,'').split(/[?#]/)[0];
  if (key === "feed") return "feed";
  if (key === "alerts") return "alerts";
  if (key === "profile") return "profile";
  return "map";
}

export default function App(){
  const [tab, setTab] = useState<Tab>(routeToTab(location.hash || "#/map"));
  useEffect(()=> {
    const onHash = () => setTab(routeToTab(location.hash || "#/map"));
    window.addEventListener("hashchange", onHash);
    return () => window.removeEventListener("hashchange", onHash);
  },[]);

  useEffect(()=> {
    const target = tab === "map" ? "#/map" : tab === "feed" ? "#/feed" : tab === "alerts" ? "#/alerts" : "#/profile";
    if (location.hash !== target) location.hash = target;
  }, [tab]);

  const onFab = () => {
    if (tab === "map") location.hash = "#/add-place";
    else if (tab === "feed") location.hash = "#/add-catch";
    else alert("Скоро тут появится действие");
  };

  return (
    <div className="relative w-full h-screen bg-gray-50">
      {tab==="map" && <MapScreen/>}
      {tab==="feed" && <FeedScreen/>}
      {tab==="alerts" && <NotificationsPage/>}
      {tab==="profile" && <ProfilePage/>}

      <BottomNav active={tab} onChange={setTab} onFab={onFab}/>
    </div>
  );
}
TSX

# ---------- 8) Безопасное расширение api.ts ----------
# Если файла нет — создаём минимальный
if [ ! -f "$SRC/data/api.ts" ]; then
  cat > "$SRC/data/api.ts" <<'TS'
const BASE = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";

async function http<T=any>(path: string, init?: RequestInit): Promise<T>{
  const r = await fetch(`${BASE}${path}`, { credentials: "include", ...init });
  if(!r.ok) throw new Error(String(r.status));
  return r.json();
}

export const api = {
  points: (q:string)=> http(`/map/points${q}`),
  feed: (q:string)=> http(`/feed${q}`),
  notifications: ()=> http(`/notifications`),
  me: ()=> http(`/profile/me`),
};
export default api;
TS
else
  # Аппендим недостающие функции, не трогая существующие
  if ! grep -q "notifications" "$SRC/data/api.ts"; then
    cat >> "$SRC/data/api.ts" <<'TS'

// added by script: notifications & me helpers
export async function notifications(){
  const BASE = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
  const r = await fetch(`${BASE}/notifications`, { credentials: "include" });
  if(!r.ok) throw new Error(String(r.status));
  const j = await r.json();
  return Array.isArray((j as any).items) ? (j as any).items : [];
}
export async function profileMe(){
  const BASE = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
  const r = await fetch(`${BASE}/profile/me`, { credentials: "include" });
  if(!r.ok) throw new Error(String(r.status));
  return (await r.json()) as any;
}
TS
  fi
fi

echo "✓ Уведомления и Профиль добавлены.
- src/screens/NotificationsPage.tsx
- src/screens/ProfilePage.tsx
- src/components/BottomNav.tsx
- src/components/Icon.tsx
- src/config/ui.ts
- src/styles/ui.css
- src/App.tsx
- src/data/api.ts (обновлён / дополнен)

Не забудь подключить styles/ui.css (в main.tsx или index.css):
  import './styles/ui.css';
"