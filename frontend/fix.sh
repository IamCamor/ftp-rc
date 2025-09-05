#!/usr/bin/env bash
set -euo pipefail

FRONT="./frontend"

mkdir -p "$FRONT/src" "$FRONT/src/pages" "$FRONT/src/styles"

############################################
# 1) config.ts — единые базовые настройки
############################################
cat > "$FRONT/src/config.ts" <<'EOF'
export const API_BASE = 'https://api.fishtrackpro.ru/api/v1';
export const TILES_URL = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

// Ширина/высота шапки и нижнего меню — для расчёта высоты карты
export const UI_DIMENSIONS = {
  header: 64,     // px
  bottomNav: 64,  // px
};
EOF

############################################
# 2) api.ts — строгие пути /api/v1 и CORS-дружелюбно
############################################
cat > "$FRONT/src/api.ts" <<'EOF'
import { API_BASE } from './config';

type Method = 'GET'|'POST'|'PUT'|'PATCH'|'DELETE';

async function http<T>(
  path: string,
  { method='GET', body, auth=false, query }: { method?: Method; body?: any; auth?: boolean; query?: Record<string, any> } = {}
): Promise<T> {
  const url = new URL(API_BASE + path);
  if (query) {
    Object.entries(query).forEach(([k,v])=>{
      if (v !== undefined && v !== null) url.searchParams.set(k, String(v));
    });
  }

  const opts: RequestInit = {
    method,
    mode: 'cors',
    credentials: auth ? 'include' : 'omit',
    headers: {
      ...(body instanceof FormData ? {} : {'Content-Type':'application/json'}),
      'Accept':'application/json',
    },
    body: body ? (body instanceof FormData ? body : JSON.stringify(body)) : undefined,
  };

  const res = await fetch(url.toString(), opts);
  if (!res.ok) {
    // Пытаемся достать json-ошибку, но не падаем если не json
    let detail = '';
    try { detail = JSON.stringify(await res.clone().json()).slice(0,500); } catch { detail = (await res.text()).slice(0,500); }
    throw new Error(`${res.status} ${res.statusText} :: ${detail}`);
  }
  if (res.status === 204) return {} as T;
  const ct = res.headers.get('content-type') || '';
  return ct.includes('application/json') ? res.json() as Promise<T> : (await res.text() as unknown as T);
}

export const api = {
  /* Публичные */
  feed: (params: {limit?:number; offset?:number; sort?:'new'|'top'; fish?:string; near?:string}={}) =>
    http('/feed', { query: params }),

  points: (params: {limit?:number; bbox?:string; filter?:string}={}) =>
    http('/map/points', { query: params }),

  catchById: (id: number|string) =>
    http(`/catch/${id}`),

  weather: (params: {lat:number; lng:number; dt?:number}) =>
    http('/weather', { query: params }),

  addCatch: (payload: any) =>
    http('/catches', { method:'POST', body: payload }),

  addPlace: (payload: any) =>
    http('/points', { method:'POST', body: payload }),

  /* Приватные (cookie нужны) */
  me: () => http('/profile/me', { auth:true }),
  notifications: () => http('/notifications', { auth:true }),
  likeToggle: (catchId: number|string) => http(`/catch/${catchId}/like`, { method:'POST', auth:true }),
  addComment: (catchId: number|string, payload: {text:string}) => http(`/catch/${catchId}/comments`, { method:'POST', body: payload, auth:true }),
  followToggle: (userId: number|string) => http(`/follow/${userId}`, { method:'POST', auth:true }),
};
EOF

############################################
# 3) styles/app.css — высота карты + glassmorphism
############################################
cat > "$FRONT/src/styles/app.css" <<'EOF'
:root {
  --blur-bg: rgba(18, 18, 18, 0.5);
  --blur-bg-light: rgba(255,255,255,0.55);
  --backdrop: blur(12px) saturate(120%);
}

.glass {
  background: var(--blur-bg);
  backdrop-filter: var(--backdrop);
  -webkit-backdrop-filter: var(--backdrop);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px;
}

.glass-light {
  background: var(--blur-bg-light);
  backdrop-filter: var(--backdrop);
  -webkit-backdrop-filter: var(--backdrop);
  border: 1px solid rgba(0,0,0,0.06);
  border-radius: 16px;
}

/* Контейнер карты — на всю высоту окна за вычетом шапки/нави */
#map-container {
  width: 100%;
  height: 100dvh; /* запас по умолчанию */
}

.leaflet-container {
  width: 100%;
  height: 100%;
}

/* Небольшая тень для панелей */
.card {
  border-radius: 14px;
  box-shadow: 0 10px 25px rgba(0,0,0,0.12);
}
EOF

############################################
# 4) MapScreen.tsx — вернуть карту и не падать на данных
############################################
cat > "$FRONT/src/pages/MapScreen.tsx" <<'EOF'
import React, { useEffect, useMemo, useRef, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { api } from '../api';
import { TILES_URL, UI_DIMENSIONS } from '../config';

type Point = {
  id: number;
  type?: string;
  lat: number;
  lng: number;
  title?: string;
  photos?: string[];
  catch_id?: number;
};

const defaultCenter: [number, number] = [55.751244, 37.618423];

const pinIcon = new L.Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25,41],
  iconAnchor: [12,41],
});

function BoundsListener({ onBounds }: {onBounds: (b:L.LatLngBounds)=>void}) {
  const map = useMapEvents({
    moveend: () => onBounds(map.getBounds()),
    zoomend: () => onBounds(map.getBounds()),
    load: () => onBounds(map.getBounds()),
  });
  return null;
}

export default function MapScreen() {
  const [points, setPoints] = useState<Point[]>([]);
  const [error, setError] = useState<string>('');
  const containerRef = useRef<HTMLDivElement>(null);

  // Делаем явную высоту: 100dvh - header - bottomNav
  useEffect(()=>{
    const h = window.innerHeight - UI_DIMENSIONS.header - UI_DIMENSIONS.bottomNav;
    if (containerRef.current) containerRef.current.style.height = `${Math.max(h, 300)}px`;
  },[]);

  const loadPoints = async (b?: L.LatLngBounds) => {
    try {
      setError('');
      const bbox = b
        ? `${b.getWest().toFixed(2)},${b.getSouth().toFixed(2)},${b.getEast().toFixed(2)},${b.getNorth().toFixed(2)}`
        : undefined;

      const data: any = await api.points({ limit: 500, bbox });
      const list = Array.isArray(data?.items) ? data.items
                 : Array.isArray(data) ? data
                 : Array.isArray(data?.data) ? data.data
                 : [];

      // Нормализуем
      const normalized: Point[] = list.map((p:any)=>({
        id: Number(p.id ?? p.point_id ?? Math.random()*1e9),
        type: p.type ?? p.category ?? 'spot',
        lat: Number(p.lat ?? p.latitude),
        lng: Number(p.lng ?? p.longitude),
        title: p.title ?? p.name ?? '',
        photos: Array.isArray(p.photos) ? p.photos : (p.photo_url ? [p.photo_url] : []),
        catch_id: p.catch_id ? Number(p.catch_id) : undefined,
      })).filter(p => !Number.isNaN(p.lat) && !Number.isNaN(p.lng));

      setPoints(normalized);
    } catch (e:any) {
      setError(e?.message || 'Ошибка загрузки точек');
      setPoints([]);
    }
  };

  const openEntity = (p: Point) => {
    if (p.catch_id) {
      window.location.href = `/catch/${p.catch_id}`;
    } else {
      window.location.href = `/place/${p.id}`;
    }
  };

  return (
    <div className="p-3">
      <div className="glass card p-2 mb-3">
        <div className="flex items-center justify-between">
          <strong>Карта</strong>
          <div className="text-sm opacity-80">Панорамный просмотр точек и уловов</div>
        </div>
      </div>

      <div id="map-container" ref={containerRef} className="card overflow-hidden">
        <MapContainer center={defaultCenter} zoom={10} style={{width:'100%', height:'100%'}}>
          <TileLayer url={TILES_URL} attribution="&copy; OpenStreetMap contributors" />
          <BoundsListener onBounds={(b)=>loadPoints(b)} />
          {points.map(p=>(
            <Marker key={`${p.id}-${p.lat}-${p.lng}`} position={[p.lat, p.lng]} icon={pinIcon}>
              <Popup>
                <div style={{maxWidth: 240}}>
                  <div className="font-medium mb-2">{p.title || 'Точка'}</div>
                  {p.photos && p.photos.length > 0 ? (
                    <div
                      style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:8}}
                    >
                      {p.photos.slice(0,4).map((src, idx)=>(
                        <img
                          key={idx}
                          src={src}
                          alt="photo"
                          style="cursor:pointer; width:100%; height:80px; object-fit:cover; border-radius:8px"
                          onClick={()=>openEntity(p)}
                          onKeyDown={(e)=>{ if (e.key==='Enter') openEntity(p); }}
                          tabindex="0"
                        />
                      ))}
                    </div>
                  ) : (
                    <button
                      className="glass-light mt-1 px-3 py-2"
                      onClick={()=>openEntity(p)}
                    >
                      Открыть
                    </button>
                  )}
                </div>
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>
      {!!error && (
        <div className="mt-3 text-red-500 text-sm">Ошибка карты: {error}</div>
      )}
    </div>
  );
}
EOF

############################################
# 5) NotificationsPage.tsx — правильный путь и мягкие ошибки
############################################
cat > "$FRONT/src/pages/NotificationsPage.tsx" <<'EOF'
import React, { useEffect, useState } from 'react';
import { api } from '../api';

type Notice = {
  id: number|string;
  type: string;
  title?: string;
  message?: string;
  created_at?: string;
  link?: string;
};

export default function NotificationsPage() {
  const [items, setItems] = useState<Notice[]>([]);
  const [error, setError] = useState('');

  useEffect(()=>{
    (async ()=>{
      try {
        setError('');
        const data: any = await api.notifications();
        const list = Array.isArray(data?.items) ? data.items
                   : Array.isArray(data?.data) ? data.data
                   : Array.isArray(data) ? data : [];
        setItems(list);
      } catch (e:any) {
        // Часто: 404 если ручка ещё не сделана на бэке, или CORS
        setError(e?.message || 'Недоступно');
        setItems([]);
      }
    })();
  },[]);

  return (
    <div className="p-3">
      <div className="glass card p-3 mb-3">
        <strong>Уведомления</strong>
      </div>

      {error && (
        <div className="text-sm text-amber-600 mb-3">
          {error.includes('404') ? 'Ручка /api/v1/notifications ещё не доступна' : error}
        </div>
      )}

      {items.length === 0 && !error && (
        <div className="opacity-70 text-sm">Пока уведомлений нет</div>
      )}

      <div className="grid gap-2">
        {items.map(n=>(
          <div key={String(n.id)} className="glass-light p-3">
            <div className="text-xs opacity-70">{n.type}</div>
            <div className="font-medium">{n.title || n.message || 'Событие'}</div>
            {n.link && (
              <a className="text-blue-600 underline" href={n.link}>Открыть</a>
            )}
            {n.created_at && (
              <div className="text-xs opacity-70 mt-1">{new Date(n.created_at).toLocaleString()}</div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
EOF

############################################
# 6) ProfilePage.tsx — правильный путь и фоллбэк
############################################
cat > "$FRONT/src/pages/ProfilePage.tsx" <<'EOF'
import React, { useEffect, useState } from 'react';
import { api } from '../api';

type Profile = {
  id: number|string;
  name: string;
  avatar?: string;
  points?: number;
};

export default function ProfilePage() {
  const [me, setMe] = useState<Profile | null>(null);
  const [error, setError] = useState('');

  useEffect(()=>{
    (async ()=>{
      try {
        setError('');
        const data: any = await api.me();
        setMe({
          id: data?.id ?? 'me',
          name: data?.name ?? 'Гость',
          avatar: data?.avatar ?? data?.photo_url ?? '',
          points: data?.points ?? data?.bonus ?? 0,
        });
      } catch (e:any) {
        setError(e?.message || 'Недоступно');
        setMe(null);
      }
    })();
  },[]);

  return (
    <div className="p-3">
      <div className="glass card p-3 mb-3">
        <strong>Профиль</strong>
      </div>

      {error && (
        <div className="text-sm text-amber-600 mb-3">
          {error.includes('401') ? 'Требуется вход' : error}
        </div>
      )}

      {me ? (
        <div className="glass-light p-4 flex items-center gap-3">
          <img
            src={me.avatar || '/default-avatar.png'}
            alt="avatar"
            width="64" height="64"
            style="border-radius:50%; object-fit:cover"
          />
          <div>
            <div className="text-lg font-medium">{me.name}</div>
            <div className="opacity-75 text-sm">Баллы: {me.points ?? 0}</div>
          </div>
        </div>
      ) : (
        !error && <div className="opacity-70 text-sm">Загрузка…</div>
      )}
    </div>
  );
}
EOF

echo "✅ Обновлены: config.ts, api.ts, styles/app.css, MapScreen.tsx, NotificationsPage.tsx, ProfilePage.tsx"

echo
echo "⚙️  Что ещё важно на бэке:"
echo "1) В routes/api.php должны существовать маршруты: GET /api/v1/feed, GET /api/v1/map/points, GET /api/v1/profile/me, GET /api/v1/notifications."
echo "2) В config/cors.php (Laravel) whitelisting: https://www.fishtrackpro.ru, supports_credentials=true."
echo "3) После любых правок CORS на бэке: php artisan config:clear && php artisan config:cache"