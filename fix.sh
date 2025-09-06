#!/usr/bin/env bash
set -euo pipefail

FRONTEND_DIR="frontend"
SRC="$FRONTEND_DIR/src"

[ -d "$SRC" ] || { echo "❌ Не найден каталог $SRC (запусти из корня проекта, где лежит папка $FRONTEND_DIR)"; exit 1; }

mkdir -p "$SRC/pages"

#####################################
# api.ts — нормализация ответа points() и единые URL
#####################################
cat > "$SRC/api.ts" <<'TS'
import config from './config';

type FetchOpts = { method?: 'GET'|'POST'|'PUT'|'DELETE'; body?: any; headers?: Record<string,string>; credentials?: RequestCredentials };

async function http<T = any>(path: string, opts: FetchOpts = {}): Promise<T> {
  const url = path.startsWith('http') ? path : `${config.apiBase}${path}`;
  const headers: Record<string,string> = { 'Accept': 'application/json' };
  let body: BodyInit | undefined;

  if (opts.body !== undefined) {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(opts.body);
  }

  const res = await fetch(url, {
    method: opts.method ?? 'GET',
    headers: { ...headers, ...(opts.headers ?? {}) },
    credentials: 'include', // чтобы работали куки/сессии
    body
  });

  // Некоторые наши ручки возвращают 204 без body
  if (res.status === 204) return undefined as unknown as T;

  const text = await res.text();
  let json: any;
  try { json = text ? JSON.parse(text) : {}; } catch { json = text; }

  if (!res.ok) {
    const e: any = new Error((json && (json.message || json.error)) || `HTTP ${res.status}`);
    e.status = res.status; e.payload = json;
    throw e;
  }
  return json as T;
}

export type PointsQuery = { limit?: number; bbox?: string | [number,number,number,number]; filter?: string };

function normalizeArray(payload: any): any[] {
  if (Array.isArray(payload)) return payload;
  if (payload == null) return [];
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.results)) return payload.results;
  if (Array.isArray(payload.rows)) return payload.rows;
  // иногда прилетает объект с числовыми ключами — превратим в массив значений
  if (typeof payload === 'object') {
    const vals = Object.values(payload);
    if (vals.length && vals.every(v => typeof v === 'object')) return vals as any[];
  }
  return [];
}

// === MAP ===
export async function points(q: PointsQuery = {}): Promise<any[]> {
  const p = new URLSearchParams();
  if (q.limit) p.set('limit', String(q.limit));
  if (q.filter) p.set('filter', q.filter);
  if (q.bbox) {
    const s = Array.isArray(q.bbox) ? q.bbox.join(',') : q.bbox;
    p.set('bbox', s);
  }
  const res = await http<any>(`/map/points?${p.toString()}`);
  return normalizeArray(res);
}

// === FEED ===
export async function feed(limit = 10, offset = 0): Promise<any[]> {
  const res = await http<any>(`/feed?limit=${limit}&offset=${offset}`);
  return normalizeArray(res);
}

// === PROFILE ===
export async function profileMe(): Promise<any> {
  return http<any>('/profile/me');
}

// === NOTIFICATIONS ===
export async function notifications(): Promise<any[]> {
  const res = await http<any>('/notifications');
  return normalizeArray(res);
}

// === WEATHER FAVS (локально, пока бэкенд не готов) ===
const LS_KEY = 'weather_favs_v1';
export type WeatherFav = { lat: number, lng: number, name: string };
export function getWeatherFavs(): WeatherFav[] {
  try { return JSON.parse(localStorage.getItem(LS_KEY) || '[]'); } catch { return []; }
}
export async function saveWeatherFav(f: WeatherFav): Promise<void> {
  const list = getWeatherFavs();
  list.push(f);
  localStorage.setItem(LS_KEY, JSON.stringify(list));
}
TS

#####################################
# AppRoot.tsx — BrowserRouter + нормальные маршруты + 404
#####################################
cat > "$SRC/AppRoot.tsx" <<'TS'
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';

import Header from './components/Header';
import BottomNav from './components/BottomNav';

import FeedScreen from './pages/FeedScreen';
import MapScreen from './pages/MapScreen';
import AddCatchPage from './pages/AddCatchPage';
import AddPlacePage from './pages/AddPlacePage';
import NotificationsPage from './pages/NotificationsPage';
import ProfilePage from './pages/ProfilePage';
import WeatherPage from './pages/WeatherPage';
import CatchDetailPage from './pages/CatchDetailPage';
import PlaceDetailPage from './pages/PlaceDetailPage';
import NotFound from './pages/NotFound';

const AppRoot: React.FC = () => {
  return (
    <BrowserRouter>
      <Header />
      <Routes>
        <Route path="/" element={<Navigate to="/feed" replace />} />
        <Route path="/feed" element={<FeedScreen />} />
        <Route path="/map" element={<MapScreen />} />
        <Route path="/add/catch" element={<AddCatchPage />} />
        <Route path="/add/place" element={<AddPlacePage />} />
        <Route path="/alerts" element={<NotificationsPage />} />
        <Route path="/profile" element={<ProfilePage />} />
        <Route path="/weather" element={<WeatherPage />} />
        <Route path="/catch/:id" element={<CatchDetailPage />} />
        <Route path="/place/:id" element={<PlaceDetailPage />} />
        <Route path="*" element={<NotFound />} />
      </Routes>
      <BottomNav />
    </BrowserRouter>
  );
};

export default AppRoot;
TS

#####################################
# main.tsx — гарантированный импорт стилей и монтирование AppRoot
#####################################
cat > "$SRC/main.tsx" <<'TS'
import React from 'react';
import { createRoot } from 'react-dom/client';
import './styles/app.css';
import AppRoot from './AppRoot';

const el = document.getElementById('root');
if (!el) {
  throw new Error('#root not found');
}
const root = createRoot(el);
console.log('[boot] App mounted');
root.render(<AppRoot />);
TS

#####################################
# pages/NotFound.tsx — страница 404
#####################################
cat > "$SRC/pages/NotFound.tsx" <<'TS'
import React from 'react';
import { Link } from 'react-router-dom';

const NotFound: React.FC = () => {
  return (
    <div className="container">
      <div className="glass card" style={{padding:20, marginTop:20}}>
        <h2>Страница не найдена (404)</h2>
        <p className="subtle">Похоже, такой страницы нет. Вернёмся на главную?</p>
        <div style={{display:'flex', gap:8}}>
          <Link className="btn" to="/feed"><span className="icon">home</span> Лента</Link>
          <Link className="btn" to="/map"><span className="icon">map</span> Карта</Link>
        </div>
      </div>
    </div>
  );
};
export default NotFound;
TS

#####################################
# pages/MapScreen.tsx — безопасная обработка ответа points()
#####################################
cat > "$SRC/pages/MapScreen.tsx" <<'TS'
import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { points, saveWeatherFav } from '../api';
import { loadLeaflet } from '../utils/leafletLoader';

type Point = {
  id: number|string;
  lat: number;
  lng: number;
  type?: 'place'|'catch'|string;
  title?: string;
  species?: string;
  media?: string[];
  photo_url?: string;
};

const DEFAULT_CENTER: [number, number] = [55.75, 37.61];
const DEFAULT_ZOOM = 10;

const MapScreen: React.FC = () => {
  const nav = useNavigate();
  const mapEl = useRef<HTMLDivElement|null>(null);
  const mapRef = useRef<any>(null);
  const [ready, setReady] = useState(false);

  // init map
  useEffect(() => {
    let canceled = false;
    (async () => {
      try {
        const L = await loadLeaflet();
        if (canceled) return;
        const map = L.map(mapEl.current!).setView(DEFAULT_CENTER, DEFAULT_ZOOM);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19, attribution: '&copy; OpenStreetMap' }).addTo(map);
        mapRef.current = map;
        setReady(true);

        map.on('click', async (e: any) => {
          const lat = e.latlng.lat, lng = e.latlng.lng;
          const m = L.marker([lat,lng]).addTo(map);
          m.bindPopup(`
            <div style="padding:6px;min-width:200px">
              <b>Новая точка</b><br/>
              ${lat.toFixed(5)}, ${lng.toFixed(5)}<br/><br/>
              <button id="btnAddPlace" style="padding:6px 10px;border-radius:8px;border:1px solid #fff3;background:#ffffff14;color:#fff">Добавить место</button>
              <button id="btnSaveWeather" style="padding:6px 10px;border-radius:8px;border:1px solid #fff3;background:#ffffff14;color:#fff;margin-left:6px">В погоду</button>
            </div>
          `).openPopup();

          setTimeout(() => {
            document.getElementById('btnAddPlace')?.addEventListener('click', () => nav(`/add/place?lat=${lat}&lng=${lng}`), { once: true });
            document.getElementById('btnSaveWeather')?.addEventListener('click', async () => {
              await saveWeatherFav({ lat, lng, name: `Точка ${lat.toFixed(3)},${lng.toFixed(3)}` });
              alert('Сохранено в избранные точки погоды');
            }, { once: true });
          }, 0);
        });

      } catch (e) {
        console.error('Leaflet init error', e);
      }
    })();
    return () => { canceled = true; try { mapRef.current?.remove(); } catch {} };
  }, [nav]);

  // load pins
  useEffect(() => {
    if (!ready) return;
    (async () => {
      try {
        const L = (window as any).L;
        const raw = await points({ limit: 500 });
        const list: Point[] = Array.isArray(raw) ? raw : [];
        if (!Array.isArray(raw)) {
          console.warn('points(): ожидался массив, пришло', raw);
        }
        list.forEach(p => {
          const m = L.marker([p.lat, p.lng]).addTo(mapRef.current);
          const img = (p.media && p.media[0]) || p.photo_url || '';
          const safeTitle = (p.title || p.species || 'Точка').replace(/</g,'&lt;').replace(/>/g,'&gt;');
          const href = p.type === 'catch' ? `/catch/${p.id}` : `/place/${p.id}`;
          const card = `
            <div style="min-width:220px">
              ${img ? `<img src="${img}" style="width:100%;height:120px;object-fit:cover;border-radius:10px;margin-bottom:6px" />` : ''}
              <div style="font-weight:600;margin-bottom:6px">${safeTitle}</div>
              <div style="display:flex;gap:6px">
                <a href="${href}" class="leaflet-popup-link" data-id="${p.id}">Открыть</a>
              </div>
            </div>`;
          m.bindPopup(card);
          m.on('popupopen', () => {
            const el = document.querySelector('.leaflet-popup a.leaflet-popup-link') as HTMLAnchorElement | null;
            if (el) {
              el.addEventListener('click', (ev) => {
                ev.preventDefault();
                nav(el.getAttribute('href') || '/');
              }, { once: true });
            }
          });
        });
      } catch (e) {
        console.error('points load error', e);
      }
    })();
  }, [ready, nav]);

  return (
    <div className="map-wrap">
      <div id="map" ref={mapEl} className="glass" />
      <div className="fab">
        <button className="btn" onClick={() => nav('/add/place')}>
          <span className="icon">add_location_alt</span> Место
        </button>
        <button className="btn" onClick={() => nav('/add/catch')}>
          <span className="icon">add_circle</span> Улов
        </button>
      </div>
    </div>
  );
};

export default MapScreen;
TS

echo "✅ Обновлено:"
echo " - $SRC/api.ts"
echo " - $SRC/AppRoot.tsx"
echo " - $SRC/main.tsx"
echo " - $SRC/pages/NotFound.tsx"
echo " - $SRC/pages/MapScreen.tsx"
echo
echo "Дальше:"
echo " 1) cd $FRONTEND_DIR"
echo " 2) npm run dev   (или npm run build && serve из nginx)"