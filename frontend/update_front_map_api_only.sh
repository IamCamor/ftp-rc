#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Обновляю фронт под API-only карту…"

ROOT="$(pwd)"
SRC="$ROOT/src"
COMP="$SRC/components"
DATA="$SRC/data"
SCREENS="$SRC/screens"

mkdir -p "$COMP" "$DATA" "$SCREENS"

########################################
# package.json — гарантируем нужные deps
########################################
if [ -f "$ROOT/package.json" ]; then
  node - <<'NODE'
const fs=require('fs'); const p=JSON.parse(fs.readFileSync('package.json','utf8'));
p.dependencies = {...p.dependencies,
  "leaflet":"^1.9.4",
  "lucide-react":"^0.451.0",
  "react":"18.3.1",
  "react-dom":"18.3.1",
  "react-leaflet":"^4.2.1",
  "react-router-dom":"^6.26.2"
};
p.devDependencies = {...p.devDependencies,
  "@types/react":"^18.3.5",
  "@types/react-dom":"^18.3.0",
  "@vitejs/plugin-react-swc":"^3.5.0",
  "tailwindcss":"^3.4.10",
  "postcss":"^8.4.39",
  "autoprefixer":"^10.4.19",
  "typescript":"^5.5.4",
  "vite":"^5.4.2"
};
fs.writeFileSync('package.json', JSON.stringify(p,null,2));
console.log('package.json updated');
NODE
else
  echo "⚠️ package.json не найден — пропускаю"
fi

########################################
# .env.example — подсказка по API
########################################
if [ ! -f "$ROOT/.env.example" ]; then
cat > "$ROOT/.env.example" <<'ENV'
# URL бэкенда БЕЗ финального слеша
VITE_API_BASE=https://api.fishtrackpro.ru
ENV
fi

########################################
# Tailwind / PostCSS (если нет)
########################################
if [ ! -f "$ROOT/tailwind.config.js" ]; then
cat > "$ROOT/tailwind.config.js" <<'JS'
export default {
  content: ["./index.html","./src/**/*.{ts,tsx}"],
  theme: { extend: {} },
  plugins: [],
}
JS
fi
if [ ! -f "$ROOT/postcss.config.js" ]; then
cat > "$ROOT/postcss.config.js" <<'JS'
export default { plugins: { tailwindcss: {}, autoprefixer: {} } }
JS
fi

########################################
# index.css — glass + leaflet
########################################
cat > "$SRC/index.css" <<'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;

@import "leaflet/dist/leaflet.css";

.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }

.glass { backdrop-filter: blur(20px); background: rgba(255,255,255,.20); border: 1px solid rgba(255,255,255,.3); box-shadow: 0 6px 24px rgba(0,0,0,.08); }
.glass-soft { backdrop-filter: blur(20px); background: rgba(255,255,255,.15); border-top: 1px solid rgba(255,255,255,.25); }
.grad-ig { background-image: linear-gradient(135deg,#FF7CA3 0%,#FFB88C 100%); }
CSS

########################################
# src/data/types.ts
########################################
cat > "$DATA/types.ts" <<'TS'
export type PointType = "spot"|"shop"|"slip"|"camp"|"catch"|string;

export type Point = {
  id: number;
  title: string;
  lat: number;
  lng: number;
  type?: PointType;
  description?: string|null;
  address?: string|null;
  tags?: string[]|null;
};
TS

########################################
# src/data/api.ts — ТОЛЬКО API, без демо
########################################
cat > "$DATA/api.ts" <<'TS'
import type { Point, PointType } from "./types";

const API_BASE = (import.meta as any).env?.VITE_API_BASE?.toString().trim() || "";

export type GetPointsParams = {
  filter?: PointType;
  bbox?: [number, number, number, number]; // [minLng,minLat,maxLng,maxLat]
  limit?: number;
  q?: string;
};

export async function getPoints(params: GetPointsParams = {}): Promise<Point[]> {
  if (!API_BASE) throw new Error("VITE_API_BASE is not set");

  const u = new URL(`${API_BASE}/api/v1/map/points`);
  u.searchParams.set("limit", String(params.limit ?? 500));
  if (params.filter) u.searchParams.set("filter", params.filter);
  if (params.bbox) u.searchParams.set("bbox", params.bbox.join(","));
  if (params.q) u.searchParams.set("q", params.q);

  const res = await fetch(u.toString(), { headers: { Accept: "application/json" } });
  const ct = res.headers.get("content-type") || "";
  if (!res.ok || !ct.includes("application/json")) {
    throw new Error(`Bad API response: ${res.status}`);
  }

  const data = await res.json();
  const items: any[] = data?.items ?? data ?? [];
  return items.map((it: any, i: number) => {
    const tags: string[] | null =
      Array.isArray(it.tags) ? it.tags :
      typeof it.tags === "string" ? it.tags.split(",").map((s: string)=>s.trim()).filter(Boolean) :
      null;

    return {
      id: Number(it.id ?? i+1),
      title: String(it.title ?? `Point ${i+1}`),
      lat: Number(it.lat ?? it.latitude),
      lng: Number(it.lng ?? it.longitude),
      type: it.type ?? it.category ?? undefined,
      description: it.description ?? it.note ?? null,
      address: it.address ?? null,
      tags
    } as Point;
  });
}
TS

########################################
# src/utils/useDebounce.ts
########################################
mkdir -p "$SRC/utils"
cat > "$SRC/utils/useDebounce.ts" <<'TS'
import { useEffect, useState } from "react";
export function useDebounce<T>(value: T, ms = 400) {
  const [v, setV] = useState(value);
  useEffect(() => { const t=setTimeout(()=>setV(value), ms); return ()=>clearTimeout(t); }, [value, ms]);
  return v;
}
TS

########################################
# UI компоненты
########################################
cat > "$COMP/SearchBar.tsx" <<'TSX'
import React from "react";
type Props = { value: string; onChange: (v: string) => void; };
export default function SearchBar({ value, onChange }: Props) {
  return (
    <div className="fixed top-4 left-1/2 -translate-x-1/2 w-[92%] z-30">
      <div className="glass rounded-2xl px-4 py-2 flex items-center">
        <span className="mr-2">🔍</span>
        <input
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Поиск мест…"
          className="bg-transparent outline-none text-sm w-full text-gray-800 placeholder:text-gray-500"
        />
      </div>
    </div>
  );
}
TSX

cat > "$COMP/FilterChips.tsx" <<'TSX'
import React from "react";
import cls from "classnames";
const FILTERS = ["Все","Споты","Магазины","Слипы","Кемпинги","Уловы"] as const;
export type FilterName = typeof FILTERS[number];
type Props = { active: FilterName; onChange: (f: FilterName) => void; };
export default function FilterChips({ active, onChange }: Props) {
  return (
    <div className="fixed top-16 left-0 w-full px-3 z-20">
      <div className="flex gap-3 overflow-x-auto pb-2 no-scrollbar">
        {FILTERS.map((f) => (
          <button
            key={f}
            onClick={() => onChange(f)}
            className={cls(
              "px-4 py-2 rounded-xl text-sm whitespace-nowrap",
              active===f ? "text-white shadow grad-ig" : "glass text-gray-700"
            )}
          >
            {f}
          </button>
        ))}
      </div>
    </div>
  );
}
TSX

cat > "$COMP/BottomNav.tsx" <<'TSX'
import React from "react";
import { Home, MapPin, Bell, User, Plus } from "lucide-react";
type Tab = "feed"|"map"|"alerts"|"profile";
type Props = { onFab: () => void; active: Tab; onChange: (t: Tab) => void; };
export default function BottomNav({ onFab, active, onChange }: Props) {
  const cn = (t: Tab)=>"flex flex-col items-center "+(active===t?"text-black":"text-gray-600");
  return (
    <div className="fixed bottom-0 left-0 w-full h-16 glass-soft flex items-center justify-around z-30">
      <button className={cn("feed")} onClick={()=>onChange("feed")} aria-label="Лента">
        <Home size={22}/><span className="text-[11px]">Лента</span>
      </button>
      <button className={cn("map")} onClick={()=>onChange("map")} aria-label="Карта">
        <MapPin size={22}/><span className="text-[11px]">Карта</span>
      </button>
      <button onClick={onFab} aria-label="Добавить" className="absolute -top-6 left-1/2 -translate-x-1/2 rounded-full p-4 shadow-lg grad-ig text-white">
        <Plus size={26}/>
      </button>
      <button className={cn("alerts")} onClick={()=>onChange("alerts")} aria-label="Уведомления">
        <Bell size={22}/><span className="text-[11px]">Уведомл.</span>
      </button>
      <button className={cn("profile")} onClick={()=>onChange("profile")} aria-label="Профиль">
        <User size={22}/><span className="text-[11px]">Профиль</span>
      </button>
    </div>
  );
}
TSX

########################################
# Компонент карты — ТОЛЬКО API
########################################
cat > "$COMP/MapView.tsx" <<'TSX'
import React, { useEffect, useMemo, useRef, useState } from "react";
import { MapContainer, TileLayer, CircleMarker, Popup, useMapEvents } from "react-leaflet";
import type { LatLngBounds, LatLngExpression } from "leaflet";
import { getPoints } from "../data/api";
import type { Point } from "../data/types";
import { useDebounce } from "../utils/useDebounce";

type Props = {
  filter: "Все"|"Споты"|"Магазины"|"Слипы"|"Кемпинги"|"Уловы";
  q: string;
};

const filterToType: Record<Props["filter"], string|undefined> = {
  "Все": undefined,
  "Споты": "spot",
  "Магазины": "shop",
  "Слипы": "slip",
  "Кемпинги": "camp",
  "Уловы": "catch",
};

function BoundsWatcher({ onChange }: { onChange: (b: LatLngBounds) => void }) {
  useMapEvents({
    moveend: (e)=>onChange(e.target.getBounds()),
    zoomend: (e)=>onChange(e.target.getBounds()),
  });
  return null;
}

export default function MapView({ filter, q }: Props) {
  const [points, setPoints] = useState<Point[]>([]);
  const [error, setError] = useState<string|null>(null);
  const [bounds, setBounds] = useState<LatLngBounds|null>(null);
  const debouncedQ = useDebounce(q, 300);
  const loading = useRef(false);

  const center: LatLngExpression = [55.7558, 37.6173];

  useEffect(() => {
    let cancelled=false;
    async function load() {
      if (loading.current) return;
      loading.current = true;
      setError(null);
      try {
        const t = filterToType[filter];
        const bbox = bounds ? [bounds.getWest(), bounds.getSouth(), bounds.getEast(), bounds.getNorth()] as [number,number,number,number] : undefined;
        const items = await getPoints({ filter: t, bbox, limit: 500, q: debouncedQ });
        if (!cancelled) setPoints(items);
      } catch (e:any) {
        if (!cancelled) setError(e?.message ?? "Ошибка загрузки");
      } finally { loading.current=false; }
    }
    load();
    return ()=>{ cancelled=true; };
  }, [filter, bounds, debouncedQ]);

  // Клиентский поиск (надёжно даже если бэк игнорирует q)
  const filtered = useMemo(() => {
    const text = debouncedQ.trim().toLowerCase();
    if (!text) return points;
    return points.filter((p) => {
      const hay = [
        p.title,
        p.description ?? "",
        p.address ?? "",
        ...(p.tags ?? [])
      ].join(" ").toLowerCase();
      return hay.includes(text);
    });
  }, [points, debouncedQ]);

  return (
    <div className="w-full h-full">
      <MapContainer center={center} zoom={12} className="w-full h-full">
        <TileLayer
          url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
          attribution='&copy; <a href="https://carto.com/">CARTO</a>'
        />
        <BoundsWatcher onChange={setBounds} />

        {filtered.map((p) => (
          <CircleMarker
            key={p.id}
            center={[p.lat, p.lng]}
            radius={8}
            pathOptions={{ color:"#FF7CA3", weight:2, fillColor:"#FFB88C", fillOpacity:0.9 }}
          >
            <Popup>
              <div className="text-sm max-w-[220px]">
                <div className="font-medium">{p.title}</div>
                {p.type && <div className="text-gray-500 mt-1">Тип: {p.type}</div>}
                {p.description && <div className="mt-1">{p.description}</div>}
                {p.address && <div className="mt-1 text-gray-600">{p.address}</div>}
                {p.tags?.length ? <div className="mt-1 text-xs text-gray-500">#{p.tags.join(" #")}</div> : null}
              </div>
            </Popup>
          </CircleMarker>
        ))}
      </MapContainer>

      {error && (
        <div className="fixed top-24 left-1/2 -translate-x-1/2 px-3 py-1 text-xs rounded-md text-white bg-red-500/80 z-40">
          {error}
        </div>
      )}
    </div>
  );
}
TSX

########################################
# Экран и entrypoint
########################################
cat > "$SCREENS/MapScreen.tsx" <<'TSX'
import React, { useState } from "react";
import SearchBar from "../components/SearchBar";
import FilterChips, { FilterName } from "../components/FilterChips";
import BottomNav from "../components/BottomNav";
import MapView from "../components/MapView";

export default function MapScreen() {
  const [tab, setTab] = useState<"feed"|"map"|"alerts"|"profile">("map");
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<FilterName>("Все");
  const onFab = () => { alert("Открыть форму добавления точки"); };

  return (
    <div className="relative w-full h-screen bg-gray-100">
      <SearchBar value={search} onChange={setSearch} />
      <FilterChips active={filter} onChange={setFilter} />
      <div className="w-full h-full">
        <MapView filter={filter} q={search} />
      </div>
      <BottomNav onFab={onFab} active={tab} onChange={setTab} />
    </div>
  );
}
TSX

cat > "$SRC/main.tsx" <<'TSX'
import React from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import MapScreen from "./screens/MapScreen";
createRoot(document.getElementById("root")!).render(<MapScreen />);
TSX

echo "✅ Готово. Теперь:"
echo "   1) Установи зависимости: npm i"
echo "   2) Пропиши .env.local: VITE_API_BASE=https://api.fishtrackpro.ru (или свой URL)"
echo "   3) Запусти dev-сервер: npm run dev"
