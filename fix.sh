#!/usr/bin/env bash
set -euo pipefail

FRONT="frontend/src"
PAGES="$FRONT/pages"
COMP="$FRONT/components"
UTILS="$FRONT/utils"
STYLES="$FRONT/styles"

[ -d "frontend" ] || { echo "❌ Не найдена папка frontend (запусти из корня проекта)"; exit 1; }

mkdir -p "$PAGES" "$COMP" "$UTILS" "$STYLES"

########################################
# config.ts — базовая конфигурация
########################################
cat > "$FRONT/config.ts" <<'TS'
const config = {
  apiBase: (import.meta as any).env?.VITE_API_BASE || 'https://api.fishtrackpro.ru',
  brand: {
    name: 'FishTrack Pro',
    // укажи ссылки на свои ассеты (https, валидные сертификаты)
    logoUrl: '/logo.svg',
    defaultAvatar: '/default-avatar.png',
    bgPattern: '/bg-pattern.png',
  }
};
export default config;
TS

########################################
# api.ts — нормализованные ответы + credentials
########################################
cat > "$FRONT/api.ts" <<'TS'
import config from './config';

type FetchOpts = {
  method?: 'GET'|'POST'|'PUT'|'DELETE',
  body?: any,
  headers?: Record<string,string>,
  credentials?: RequestCredentials
};

async function http<T=any>(path:string, opts:FetchOpts = {}): Promise<T> {
  const url = path.startsWith('http') ? path : `${config.apiBase}${path}`;
  const headers:Record<string,string> = { 'Accept':'application/json' };
  let body: BodyInit | undefined;
  if (opts.body !== undefined) {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(opts.body);
  }
  const res = await fetch(url, {
    method: opts.method ?? 'GET',
    headers: { ...headers, ...(opts.headers ?? {}) },
    credentials: opts.credentials ?? 'include',
    body
  });

  if (res.status === 204) return undefined as unknown as T;
  const text = await res.text();
  let json:any; try { json = text ? JSON.parse(text) : {}; } catch { json = text; }
  if (!res.ok) {
    const e:any = new Error((json && (json.message || json.error)) || `HTTP ${res.status}`);
    e.status = res.status; e.payload = json; throw e;
  }
  return json as T;
}

function normalizeArray(payload:any): any[] {
  if (Array.isArray(payload)) return payload;
  if (!payload) return [];
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.results)) return payload.results;
  if (Array.isArray(payload.rows)) return payload.rows;
  if (typeof payload === 'object') {
    const vals = Object.values(payload);
    if (vals.length && vals.every(v => typeof v === 'object')) return vals as any[];
  }
  return [];
}

// Map
export type PointsQuery = { limit?: number; bbox?: string | [number,number,number,number]; filter?: string };
export async function points(q: PointsQuery = {}): Promise<any[]> {
  const p = new URLSearchParams();
  if (q.limit) p.set('limit', String(q.limit));
  if (q.filter) p.set('filter', q.filter);
  if (q.bbox) p.set('bbox', Array.isArray(q.bbox) ? q.bbox.join(',') : q.bbox);
  const res = await http<any>(`/api/v1/map/points?${p.toString()}`);
  return normalizeArray(res);
}

// Feed
export async function feed(limit=10, offset=0): Promise<any[]> {
  const res = await http<any>(`/api/v1/feed?limit=${limit}&offset=${offset}`);
  return normalizeArray(res);
}

// Profile
export async function profileMe(): Promise<any> {
  return http<any>('/api/v1/profile/me');
}

// Notifications
export async function notifications(): Promise<any[]> {
  const res = await http<any>('/api/v1/notifications');
  return normalizeArray(res);
}

// Weather favs (локально)
const LS_KEY = 'weather_favs_v1';
export type WeatherFav = { lat:number; lng:number; name:string };
export function getWeatherFavs(): WeatherFav[] {
  try { return JSON.parse(localStorage.getItem(LS_KEY) || '[]'); } catch { return []; }
}
export async function saveWeatherFav(f: WeatherFav): Promise<void> {
  const list = getWeatherFavs(); list.push(f);
  localStorage.setItem(LS_KEY, JSON.stringify(list));
}
TS

########################################
# utils/leafletLoader.ts — динамическая загрузка Leaflet
########################################
cat > "$UTILS/leafletLoader.ts" <<'TS'
let loading: Promise<any> | null = null;
export async function loadLeaflet(): Promise<any> {
  if ((window as any).L) return (window as any).L;
  if (!loading) {
    loading = new Promise((resolve, reject) => {
      const css = document.createElement('link');
      css.rel = 'stylesheet';
      css.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      css.onload = () => {};
      css.onerror = reject;
      document.head.appendChild(css);

      const s = document.createElement('script');
      s.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      s.async = true;
      s.onload = () => resolve((window as any).L);
      s.onerror = reject;
      document.body.appendChild(s);
    });
  }
  return loading;
}
TS

########################################
# styles/app.css — glassmorphism + Material Symbols
########################################
cat > "$STYLES/app.css" <<'CSS'
/* Material Symbols (Rounded) */
@import url('https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded');

/* базовые */
:root {
  --bg: #0b1220;
  --glass: rgba(255,255,255,0.08);
  --glass-border: rgba(255,255,255,0.18);
  --text: #e8eefc;
  --muted: #a6b0c2;
  --brand: #4da3ff;
}
* { box-sizing: border-box; }
html, body, #root { height:100%; }
body { margin:0; background: radial-gradient(1000px 600px at 20% 0%, #0f1a32 0, var(--bg) 60%); color: var(--text); font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif; }

.container { width:100%; max-width: 960px; margin: 0 auto; padding: 12px; }

.glass {
  backdrop-filter: blur(12px);
  background: var(--glass);
  border: 1px solid var(--glass-border);
  border-radius: 18px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.25);
}
.card { padding: 12px; }

.btn {
  display:inline-flex; align-items:center; gap:8px;
  padding: 10px 14px; border-radius: 12px; border: 1px solid var(--glass-border);
  background: linear-gradient(180deg, rgba(255,255,255,0.08), rgba(255,255,255,0.04));
  color: var(--text); text-decoration:none; cursor:pointer;
}
.btn:hover { border-color: #ffffff55; }
.subtle { color: var(--muted); }

.icon, .material-symbols-rounded {
  font-family: "Material Symbols Rounded";
  font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
  font-style: normal; font-weight: normal; font-size: 20px; line-height: 1;
}

/* Header / BottomNav */
.header { position: sticky; top:0; z-index: 20; padding: 8px 12px; display:flex; gap:8px; align-items:center; justify-content:space-between; }
.brand { display:flex; gap:10px; align-items:center; }
.brand img { width:28px; height:28px; border-radius:8px; }
.nav-actions { display:flex; gap:8px; align-items:center; }

.bottom-nav {
  position: sticky; bottom:0; z-index: 20; margin: 10px; padding: 6px;
  display:flex; justify-content:space-around; align-items:center;
}

/* Map */
.map-wrap { position: relative; height: calc(100vh - 120px); margin: 10px; }
#map { position:absolute; inset:0; border-radius: 16px; }
.fab { position: absolute; right: 12px; bottom: 12px; display:flex; flex-direction:column; gap:8px; }
.leaflet-container { border-radius: 16px; }

/* Feed list */
.list { display:grid; gap:10px; margin: 10px; }
.item { padding: 10px; display:flex; gap:12px; }
.item img.thumb { width:84px; height:84px; object-fit:cover; border-radius: 12px; }
.item .meta { display:flex; flex-direction:column; gap:6px; }
.item .meta .title { font-weight:600; }

/* links reset */
a { color: var(--brand); }
a.btn { color: var(--text); }
CSS

########################################
# components/Header.tsx — default export
########################################
cat > "$COMP/Header.tsx" <<'TS'
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';

const Header: React.FC = () => {
  const loc = useLocation();
  return (
    <div className="header glass">
      <div className="brand">
        <img src={config.brand.logoUrl} alt="logo"/>
        <strong>{config.brand.name}</strong>
      </div>
      <div className="nav-actions">
        <Link className="btn" to="/weather" title="Погода">
          <span className="material-symbols-rounded">sunny</span>
        </Link>
        <Link className="btn" to="/alerts" title="Уведомления">
          <span className="material-symbols-rounded">notifications</span>
        </Link>
        <Link className="btn" to="/profile" title="Профиль">
          <span className="material-symbols-rounded">account_circle</span>
        </Link>
      </div>
    </div>
  );
};
export default Header;
TS

########################################
# components/BottomNav.tsx — default export
########################################
cat > "$COMP/BottomNav.tsx" <<'TS'
import React from 'react';
import { Link, useLocation } from 'react-router-dom';

const Tab:React.FC<{to:string; icon:string; title:string}> = ({to, icon, title}) => {
  const loc = useLocation();
  const active = loc.pathname === to || (to !== '/' && loc.pathname.startsWith(to));
  return (
    <Link className="btn" to={to} title={title} style={{opacity: active ? 1 : 0.65}}>
      <span className="material-symbols-rounded">{icon}</span>
      <span style={{marginLeft:6}}>{title}</span>
    </Link>
  );
};

const BottomNav: React.FC = () => {
  return (
    <div className="bottom-nav glass">
      <Tab to="/feed" icon="home" title="Лента" />
      <Tab to="/map" icon="map" title="Карта" />
      <Tab to="/add/catch" icon="add_circle" title="Улов" />
      <Tab to="/add/place" icon="add_location_alt" title="Место" />
    </div>
  );
};
export default BottomNav;
TS

########################################
# AppRoot.tsx — BrowserRouter + маршруты
########################################
cat > "$FRONT/AppRoot.tsx" <<'TS'
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

const AppRoot: React.FC = () => (
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
export default AppRoot;
TS

########################################
# main.tsx — точка входа
########################################
cat > "$FRONT/main.tsx" <<'TS'
import React from 'react';
import { createRoot } from 'react-dom/client';
import './styles/app.css';
import AppRoot from './AppRoot';

const el = document.getElementById('root');
if (!el) throw new Error('#root not found');
createRoot(el).render(<AppRoot />);
console.log('[boot] App mounted');
TS

########################################
# pages/NotFound.tsx
########################################
cat > "$PAGES/NotFound.tsx" <<'TS'
import React from 'react';
import { Link } from 'react-router-dom';
const NotFound:React.FC = () => (
  <div className="container">
    <div className="glass card" style={{marginTop:16}}>
      <h2>404 — не найдено</h2>
      <p className="subtle">Проверьте адрес или вернитесь на главные разделы.</p>
      <div style={{display:'flex',gap:8}}>
        <Link className="btn" to="/feed"><span className="material-symbols-rounded">home</span>Лента</Link>
        <Link className="btn" to="/map"><span className="material-symbols-rounded">map</span>Карта</Link>
      </div>
    </div>
  </div>
);
export default NotFound;
TS

########################################
# pages/MapScreen.tsx — рабочая карта + пины + fav погоды
########################################
cat > "$PAGES/MapScreen.tsx" <<'TS'
import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { points, saveWeatherFav } from '../api';
import { loadLeaflet } from '../utils/leafletLoader';

type Point = { id: number|string; lat:number; lng:number; type?:'place'|'catch'|string; title?:string; species?:string; media?:string[]; photo_url?:string; };

const DEFAULT_CENTER:[number,number] = [55.75, 37.61];
const DEFAULT_ZOOM = 10;

const MapScreen:React.FC = () => {
  const nav = useNavigate();
  const mapEl = useRef<HTMLDivElement|null>(null);
  const mapRef = useRef<any>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let canceled = false;
    (async () => {
      const L = await loadLeaflet();
      if (canceled) return;
      const map = L.map(mapEl.current!).setView(DEFAULT_CENTER, DEFAULT_ZOOM);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19, attribution:'&copy; OpenStreetMap'}).addTo(map);
      mapRef.current = map; setReady(true);

      map.on('click', async (e:any) => {
        const lat = e.latlng.lat, lng = e.latlng.lng;
        const m = L.marker([lat,lng]).addTo(map);
        m.bindPopup(`
          <div style="padding:6px;min-width:220px">
            <b>Новая точка</b><br/>${lat.toFixed(5)}, ${lng.toFixed(5)}<br/><br/>
            <button id="btnAddPlace" style="padding:6px 10px;border-radius:10px;border:1px solid #fff3;background:#ffffff14;color:#fff">Добавить место</button>
            <button id="btnSaveWeather" style="padding:6px 10px;border-radius:10px;border:1px solid #fff3;background:#ffffff14;color:#fff;margin-left:6px">В погоду</button>
          </div>
        `).openPopup();
        setTimeout(() => {
          document.getElementById('btnAddPlace')?.addEventListener('click', () => nav(`/add/place?lat=${lat}&lng=${lng}`), { once:true });
          document.getElementById('btnSaveWeather')?.addEventListener('click', async () => {
            await saveWeatherFav({ lat, lng, name:`Точка ${lat.toFixed(3)},${lng.toFixed(3)}` });
            alert('Сохранено в избранные точки погоды');
          }, { once:true });
        }, 0);
      });
    })();
    return () => { canceled = true; try { mapRef.current?.remove(); } catch {} };
  }, [nav]);

  useEffect(() => {
    if (!ready) return;
    (async () => {
      try {
        const L = (window as any).L;
        const raw = await points({ limit: 500 });
        const list: Point[] = Array.isArray(raw) ? raw : [];
        list.forEach(p => {
          const m = L.marker([p.lat, p.lng]).addTo(mapRef.current);
          const img = (p.media && p.media[0]) || p.photo_url || '';
          const title = (p.title || p.species || 'Точка').replace(/</g,'&lt;').replace(/>/g,'&gt;');
          const href = p.type === 'catch' ? `/catch/${p.id}` : `/place/${p.id}`;
          const html = `
            <div style="min-width:220px">
              ${img ? `<img src="${img}" style="width:100%;height:120px;object-fit:cover;border-radius:10px;margin-bottom:6px" />` : ''}
              <div style="font-weight:600;margin-bottom:6px">${title}</div>
              <a href="${href}" class="leaflet-popup-link">Открыть</a>
            </div>`;
          m.bindPopup(html);
          m.on('popupopen', () => {
            const a = document.querySelector('.leaflet-popup a.leaflet-popup-link') as HTMLAnchorElement | null;
            a?.addEventListener('click', (ev) => { ev.preventDefault(); nav(a.getAttribute('href') || '/'); }, { once:true });
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
        <button className="btn" onClick={() => nav('/add/place')}><span className="material-symbols-rounded">add_location_alt</span>Место</button>
        <button className="btn" onClick={() => nav('/add/catch')}><span className="material-symbols-rounded">add_circle</span>Улов</button>
      </div>
    </div>
  );
};
export default MapScreen;
TS

########################################
# Простые рабочие версии остальных страниц — с default export
########################################
cat > "$PAGES/FeedScreen.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { feed } from '../api';
import { Link } from 'react-router-dom';

const FeedScreen:React.FC = () => {
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState<string>('');

  useEffect(() => {
    (async () => {
      try {
        const data = await feed(10,0);
        setItems(Array.isArray(data)?data:[]);
      } catch (e:any) {
        setErr(e?.message || 'Ошибка загрузки');
      }
    })();
  }, []);

  return (
    <div className="list">
      {err && <div className="glass card">{err}</div>}
      {items.map((it:any) => (
        <Link to={(it.type==='catch'?`/catch/${it.id}`:`/place/${it.id}`)} key={`f-${it.id}`} className="glass item">
          <img className="thumb" src={it.photo_url || (it.media && it.media[0]) || ''} alt="" />
          <div className="meta">
            <div className="title">{it.title || it.species || 'Публикация'}</div>
            <div className="subtle">{new Date(it.created_at || Date.now()).toLocaleString()}</div>
          </div>
        </Link>
      ))}
      {!items.length && !err && <div className="glass card">Пока пусто.</div>}
    </div>
  );
};
export default FeedScreen;
TS

cat > "$PAGES/AddCatchPage.tsx" <<'TS'
import React from 'react';
const AddCatchPage:React.FC = () => {
  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Добавить улов</h2>
        <p className="subtle">Форма в разработке — поля будут расширены по ТЗ.</p>
      </div>
    </div>
  );
};
export default AddCatchPage;
TS

cat > "$PAGES/AddPlacePage.tsx" <<'TS'
import React from 'react';
const AddPlacePage:React.FC = () => {
  const params = new URLSearchParams(location.search);
  const lat = params.get('lat'); const lng = params.get('lng');
  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Добавить место</h2>
        {lat && lng && <p className="subtle">Координаты: {lat}, {lng}</p>}
        <p className="subtle">Форма в разработке — заполним по ТЗ (название, описание, фото и т.д.).</p>
      </div>
    </div>
  );
};
export default AddPlacePage;
TS

cat > "$PAGES/NotificationsPage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { notifications } from '../api';

const NotificationsPage:React.FC = () => {
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState('');
  useEffect(() => {
    (async () => {
      try { setItems(await notifications()); } catch (e:any) { setErr(e?.message || 'Ошибка'); }
    })();
  }, []);
  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Уведомления</h2>
        {err && <div className="subtle">{err}</div>}
        {!items.length && !err && <div className="subtle">Пока нет уведомлений</div>}
        <ul>
          {items.map((n:any, i:number) => <li key={i}>{n.title || n.text || 'Уведомление'}</li>)}
        </ul>
      </div>
    </div>
  );
};
export default NotificationsPage;
TS

cat > "$PAGES/ProfilePage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { profileMe } from '../api';
import config from '../config';

const ProfilePage:React.FC = () => {
  const [me, setMe] = useState<any>(null);
  const [err, setErr] = useState('');
  useEffect(() => { (async ()=>{ try { setMe(await profileMe()); } catch(e:any){ setErr(e?.message||'Ошибка'); }})(); }, []);
  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Профиль</h2>
        {err && <div className="subtle">{err}</div>}
        {me ? (
          <div style={{display:'flex',gap:12,alignItems:'center'}}>
            <img src={me.avatar || config.brand.defaultAvatar} alt="" style={{width:72,height:72,borderRadius:16,objectFit:'cover'}}/>
            <div>
              <div style={{fontWeight:600}}>{me.name || 'Без имени'}</div>
              <div className="subtle">Бонусы: {me.bonus_balance ?? 0}</div>
            </div>
          </div>
        ) : !err && <div className="subtle">Загрузка…</div>}
      </div>
    </div>
  );
};
export default ProfilePage;
TS

cat > "$PAGES/WeatherPage.tsx" <<'TS'
import React, { useMemo } from 'react';
import { getWeatherFavs } from '../api';
import { Link } from 'react-router-dom';

const WeatherPage:React.FC = () => {
  const favs = useMemo(() => getWeatherFavs(), []);
  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Погода</h2>
        {!favs.length && <div className="subtle">Добавьте точку на карте (клик по карте → «В погоду»), и она появится здесь.</div>}
        <ul>
          {favs.map((f,i) => (
            <li key={i}>
              {f.name} — <Link to={`/map`}>на карте</Link>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};
export default WeatherPage;
TS

cat > "$PAGES/CatchDetailPage.tsx" <<'TS'
import React from 'react';
const CatchDetailPage:React.FC = () => {
  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Улов</h2>
        <div className="subtle">Детальная страница улова (рендер данных — после интеграции API).</div>
      </div>
    </div>
  );
};
export default CatchDetailPage;
TS

cat > "$PAGES/PlaceDetailPage.tsx" <<'TS'
import React from 'react';
const PlaceDetailPage:React.FC = () => {
  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Место</h2>
        <div className="subtle">Детальная страница места (рендер данных — после интеграции API).</div>
      </div>
    </div>
  );
};
export default PlaceDetailPage;
TS

echo "✅ Обновлены/созданы файлы:"
echo " - $FRONT/config.ts"
echo " - $FRONT/api.ts"
echo " - $UTILS/leafletLoader.ts"
echo " - $STYLES/app.css"
echo " - $COMP/Header.tsx"
echo " - $COMP/BottomNav.tsx"
echo " - $FRONT/AppRoot.tsx"
echo " - $FRONT/main.tsx"
echo " - $PAGES/NotFound.tsx"
echo " - $PAGES/MapScreen.tsx"
echo " - $PAGES/FeedScreen.tsx"
echo " - $PAGES/AddCatchPage.tsx"
echo " - $PAGES/AddPlacePage.tsx"
echo " - $PAGES/NotificationsPage.tsx"
echo " - $PAGES/ProfilePage.tsx"
echo " - $PAGES/WeatherPage.tsx"
echo " - $PAGES/CatchDetailPage.tsx"
echo " - $PAGES/PlaceDetailPage.tsx"

echo
echo "Дальше:"
echo " 1) cd frontend"
echo " 2) npm run dev   — для локальной проверки"
echo "    или npm run build и задеплоить статику"
echo
echo "Важно для прод-сервера (Nginx):"
echo "  location / { try_files \$uri \$uri/ /index.html; }"