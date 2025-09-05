#!/bin/bash
set -euo pipefail

# --- пути ---
SRC_DIR="src"
PAGES_DIR="$SRC_DIR/pages"
PUBLIC_DIR="public"
ASSETS_DIR="$PUBLIC_DIR/assets"
PINS_DIR="$ASSETS_DIR/pins"

mkdir -p "$PINS_DIR"

echo "🖼  Кладу базовые assets…"
# Лого
cat > "$ASSETS_DIR/logo.png" <<'BIN'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGAAAAAEAAGjCh0iAAAAAElFTkSuQmCC
BIN
# Аватар по умолчанию
cat > "$ASSETS_DIR/default-avatar.png" <<'BIN'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABH7s4xQAAAABJRU5ErkJggg==
BIN
# Фоновый паттерн
cat > "$ASSETS_DIR/pattern.png" <<'BIN'
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAKElEQVQYV2NkwA7+//9/DIwMDAyGJgYGBtF4gQGRAaQYIhNGCQAACf0A4zJk8Z8AAAAAElFTkSuQmCC
BIN

echo "📍 Кладу SVG пины…"
# минимальные SVG-иконки пинов
cat > "$PINS_DIR/spot.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="28" height="40" viewBox="0 0 24 24" fill="#2E7D32"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7Zm0 9.5A2.5 2.5 0 1 1 12 6a2.5 2.5 0 0 1 0 5.5Z"/></svg>
SVG
cat > "$PINS_DIR/catch.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="28" height="40" viewBox="0 0 24 24" fill="#1976D2"><path d="M12 2C7.58 2 4 5.58 4 10c0 4.97 5.33 10.83 7.05 12.62.52.53 1.37.53 1.89 0C14.67 20.83 20 14.97 20 10c0-4.42-3.58-8-8-8Zm-1 12-3-3 1.41-1.41L11 10.17l4.59-4.59L17 7l-6 7Z"/></svg>
SVG
cat > "$PINS_DIR/shop.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="28" height="40" viewBox="0 0 24 24" fill="#8E24AA"><path d="M4 4h16l-1 5H5L4 4Zm1 7h14v9H5v-9Zm3 2v5h2v-5H8Zm6 0v5h2v-5h-2Z"/></svg>
SVG
cat > "$PINS_DIR/base.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="28" height="40" viewBox="0 0 24 24" fill="#D84315"><path d="M12 3 2 12h3v7h6v-5h2v5h6v-7h3L12 3Z"/></svg>
SVG
cat > "$PINS_DIR/default.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="28" height="40" viewBox="0 0 24 24" fill="#455A64"><circle cx="12" cy="10" r="3"/><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7Z"/></svg>
SVG

echo "🛠  Обновляю src/api.ts (нормализация ответов)…"
# ПЕРЕЗАПИСЫВАЕМ api.ts — добавляем normalizeArray()
cat > "$SRC_DIR/api.ts" <<'TS'
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
TS

echo "🗺  Обновляю src/pages/MapScreen.tsx (защита от не-массивов и валидация координат)…"
cat > "$PAGES_DIR/MapScreen.tsx" <<'TSX'
import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from "react-leaflet";
import L, { LatLngBounds } from "leaflet";
import { API } from "../api";
import { Place } from "../types";
import { useNavigate, useSearchParams } from "react-router-dom";
import { CONFIG } from "../config";

function debounce<T extends (...args: any[]) => void>(fn: T, ms: number) {
  let t: any;
  return (...args: Parameters<T>) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
}

function BBoxListener({ onBBox }: { onBBox: (b: [number, number, number, number]) => void }) {
  const handler = useMemo(
    () =>
      debounce((map: any) => {
        const b: LatLngBounds = map.getBounds();
        const sw = b.getSouthWest();
        const ne = b.getNorthEast();
        onBBox([sw.lng, sw.lat, ne.lng, ne.lat]);
      }, 350),
    [onBBox]
  );

  useMapEvents({
    moveend(map) {
      handler((map as any).target);
    },
    zoomend(map) {
      handler((map as any).target);
    },
  });

  return null;
}

function makeIconByType(type?: string) {
  const meta = CONFIG.pinTypes[type || ""] || CONFIG.pinTypes.default;
  return L.icon({
    iconUrl: meta.iconUrl,
    iconSize: meta.size,
    iconAnchor: meta.anchor,
    popupAnchor: meta.popupAnchor,
    className: "pin-icon",
  });
}

function isValidCoord(n: any) {
  return typeof n === "number" && Number.isFinite(n);
}

export default function MapScreen() {
  const [params, setParams] = useSearchParams();
  const [points, setPoints] = useState<Place[]>([]);
  const [loading, setLoading] = useState(false);
  const cacheRef = useRef<{ bboxKey?: string; data: Place[] }>({ data: [] });
  const navigate = useNavigate();

  const initial = useMemo(() => {
    const lat = Number(params.get("lat")) || 55.75;
    const lng = Number(params.get("lng")) || 37.62;
    const z = Number(params.get("z")) || 10;
    return { lat, lng, z };
  }, [params]);

  const fetchPoints = useCallback(
    async (bbox: [number, number, number, number]) => {
      const key = bbox.join(",");
      if (cacheRef.current.bboxKey === key && cacheRef.current.data.length) {
        setPoints(cacheRef.current.data);
        return;
      }
      try {
        setLoading(true);
        const raw = await API.points(bbox, 500);
        // Защита на случай если сервер вернул не массив
        const arr: any[] = Array.isArray(raw) ? raw : [];
        // Валидация координат
        const normalized: Place[] = arr
          .map((p: any) => ({
            id: Number(p.id),
            name: String(p.name ?? p.title ?? "Точка"),
            type: p.type ?? p.kind ?? "default",
            lat: Number(p.lat ?? p.latitude),
            lng: Number(p.lng ?? p.longitude),
            photos: Array.isArray(p.photos) ? p.photos : (p.photo_url ? [p.photo_url] : []),
            description: p.description ?? p.caption ?? "",
          }))
          .filter((p) => isValidCoord(p.lat) && isValidCoord(p.lng));
        cacheRef.current = { bboxKey: key, data: normalized };
        setPoints(normalized);
      } catch (e) {
        console.error("points load error", e);
        setPoints([]); // не даём сломаться map() в JSX
      } finally {
        setLoading(false);
      }
    },
    []
  );

  const onBBox = useCallback(
    (bbox: [number, number, number, number]) => {
      fetchPoints(bbox);
    },
    [fetchPoints]
  );

  useEffect(() => {
    const delta = 0.25;
    const bbox: [number, number, number, number] = [
      initial.lng - delta,
      initial.lat - delta,
      initial.lng + delta,
      initial.lat + delta,
    ];
    fetchPoints(bbox);
  }, [initial, fetchPoints]);

  const onMapMovedPersist = (map: any) => {
    const c = map.getCenter();
    const z = map.getZoom();
    setParams({ lat: String(c.lat.toFixed(5)), lng: String(c.lng.toFixed(5)), z: String(z) }, { replace: true });
  };

  const MapEvents = () => {
    useMapEvents({
      moveend(ev) {
        onMapMovedPersist((ev as any).target);
      },
      zoomend(ev) {
        onMapMovedPersist((ev as any).target);
      },
    });
    return null;
  };

  return (
    <div className="map-page">
      <MapContainer
        center={[initial.lat, initial.lng]}
        zoom={initial.z}
        style={{ height: "100%", width: "100%" }}
      >
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution="© OpenStreetMap"
        />
        <BBoxListener onBBox={onBBox} />
        <MapEvents />
        {Array.isArray(points) && points.map((p) => (
          <Marker
            key={p.id}
            position={[p.lat, p.lng]}
            icon={makeIconByType(p.type)}
          >
            <Popup>
              <div className="popup-card" onClick={() => navigate(`/place/${p.id}`)}>
                <div className="popup-title">
                  <strong>{p.name}</strong>
                  {p.type && <span className="popup-type">{CONFIG.pinTypes[p.type]?.label || p.type}</span>}
                </div>
                {p.photos?.[0] && (
                  <img
                    src={p.photos[0]}
                    alt={p.name}
                    className="popup-photo"
                  />
                )}
                <div className="popup-link">Перейти к точке →</div>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
      {loading && <div className="map-loader">Загрузка точек…</div>}
    </div>
  );
}
TSX

echo "✅ Готово. Обновлены src/api.ts и src/pages/MapScreen.tsx, добавлены assets."
echo "ℹ️ Убедись, что у тебя есть зависимости: leaflet, react-leaflet, @mui/icons-material, @mui/material"