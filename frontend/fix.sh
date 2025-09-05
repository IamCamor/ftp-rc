#!/bin/bash
set -e

# === Директории ===
BASE_DIR="src"
COMP_DIR="$BASE_DIR/components"
PAGES_DIR="$BASE_DIR/pages"
STYLES_DIR="$BASE_DIR/styles"

echo "📂 Создаю директории..."
mkdir -p "$COMP_DIR" "$PAGES_DIR" "$STYLES_DIR"

# =========================
# src/App.tsx
# =========================
cat > $BASE_DIR/App.tsx <<'EOF'
import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
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
import "./styles/app.css";

function App() {
  return (
    <Router>
      <div className="app-container">
        <Header />
        <main className="app-main">
          <Routes>
            <Route path="/" element={<FeedScreen />} />
            <Route path="/map" element={<MapScreen />} />
            <Route path="/catch/:id" element={<CatchDetailPage />} />
            <Route path="/add-catch" element={<AddCatchPage />} />
            <Route path="/add-place" element={<AddPlacePage />} />
            <Route path="/alerts" element={<NotificationsPage />} />
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/weather" element={<WeatherPage />} />
            <Route path="/place/:id" element={<PlaceDetailPage />} />
          </Routes>
        </main>
        <BottomNav />
      </div>
    </Router>
  );
}

export default App;
EOF

# =========================
# src/main.tsx
# =========================
cat > $BASE_DIR/main.tsx <<'EOF'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "leaflet/dist/leaflet.css";

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# =========================
# src/config.ts
# =========================
cat > $BASE_DIR/config.ts <<'EOF'
/**
 * Централизованный конфиг:
 * - apiBase — обязательно с /api/v1
 * - assets — пути к логотипу/аватарке/фону
 * - icons — имена MUI-иконок (см. @mui/icons-material)
 * - pinTypes — карта типов точек к иконкам и стилям пинов
 */
export const CONFIG = {
  apiBase: "https://api.fishtrackpro.ru/api/v1",
  assets: {
    logo: "/assets/logo.png",
    avatar: "/assets/default-avatar.png",
    background: "/assets/pattern.png",
  },
  icons: {
    // глобальные
    feed: "Home",
    map: "Map",
    add: "AddCircle",
    alerts: "Notifications",
    profile: "Person",
    like: "FavoriteBorder",
    comment: "ChatBubbleOutline",
    share: "Share",
    weather: "WbSunny",
    back: "ArrowBack",
  },
  // Настройка пинов по типам
  pinTypes: {
    spot: {
      label: "Место",
      iconUrl: "/assets/pins/spot.svg",
      size: [28, 40],
      anchor: [14, 40],
      popupAnchor: [0, -36],
    },
    catch: {
      label: "Улов",
      iconUrl: "/assets/pins/catch.svg",
      size: [28, 40],
      anchor: [14, 40],
      popupAnchor: [0, -36],
    },
    shop: {
      label: "Магазин",
      iconUrl: "/assets/pins/shop.svg",
      size: [28, 40],
      anchor: [14, 40],
      popupAnchor: [0, -36],
    },
    base: {
      label: "База",
      iconUrl: "/assets/pins/base.svg",
      size: [28, 40],
      anchor: [14, 40],
      popupAnchor: [0, -36],
    },
    // fallback
    default: {
      label: "Точка",
      iconUrl: "/assets/pins/default.svg",
      size: [28, 40],
      anchor: [14, 40],
      popupAnchor: [0, -36],
    },
  } as Record<string, {
    label: string;
    iconUrl: string;
    size: [number, number];
    anchor: [number, number];
    popupAnchor: [number, number];
  }>,
} as const;
EOF

# =========================
# src/api.ts
# =========================
cat > $BASE_DIR/api.ts <<'EOF'
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
EOF

# =========================
# src/types.ts
# =========================
cat > $BASE_DIR/types.ts <<'EOF'
export interface User {
  id: number;
  name: string;
  avatar?: string;
  bonuses?: number;
}

export interface CatchItem {
  id: number;
  user: User;
  species: string;
  lat?: number;
  lng?: number;
  length?: number;
  weight?: number;
  style?: string;
  lure?: string;
  tackle?: string;
  notes?: string;
  photo_url?: string;
  created_at?: string;
}

export interface Place {
  id: number;
  name: string;
  type?: string; // spot|shop|base|catch|...
  lat: number;
  lng: number;
  photos?: string[];
  description?: string;
}
EOF

# =========================
# components/Header.tsx
# =========================
cat > $COMP_DIR/Header.tsx <<'EOF'
import React from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { CONFIG } from "../config";
import Icon from "./Icon";

function Header() {
  const loc = useLocation();
  const navigate = useNavigate();

  return (
    <header className="app-header" style={{ backgroundImage: `url(${CONFIG.assets.background})` }}>
      <div className="left">
        <img src={CONFIG.assets.logo} alt="logo" className="logo" onClick={() => navigate("/")} />
      </div>
      <nav className="right">
        <Link to="/weather" className="header-link" title="Погода">
          <Icon name={CONFIG.icons.weather} />
          <span className="hide-sm">Погода</span>
        </Link>
        <Link to="/alerts" className="header-link" title="Уведомления">
          <Icon name={CONFIG.icons.alerts} />
          <span className="badge">●</span>
        </Link>
        <Link to="/profile" className="header-link profile-link" title="Профиль">
          <img src={CONFIG.assets.avatar} alt="avatar" className="avatar" />
        </Link>
      </nav>
    </header>
  );
}

export default Header;
EOF

# =========================
# components/BottomNav.tsx
# =========================
cat > $COMP_DIR/BottomNav.tsx <<'EOF'
import React from "react";
import { NavLink } from "react-router-dom";
import Icon from "./Icon";
import { CONFIG } from "../config";

function BottomNav() {
  const nav = [
    { to: "/", icon: CONFIG.icons.feed, label: "Лента", end: true },
    { to: "/map", icon: CONFIG.icons.map, label: "Карта" },
    { to: "/add-catch", icon: CONFIG.icons.add, label: "Добавить" },
    { to: "/alerts", icon: CONFIG.icons.alerts, label: "Уведомл." },
    { to: "/profile", icon: CONFIG.icons.profile, label: "Профиль" },
  ];
  return (
    <nav className="bottom-nav">
      {nav.map((i) => (
        <NavLink
          key={i.to}
          to={i.to}
          end={i.end as any}
          className={({ isActive }) => "bn-item" + (isActive ? " active" : "")}
        >
          <Icon name={i.icon} />
          <span>{i.label}</span>
        </NavLink>
      ))}
    </nav>
  );
}
export default BottomNav;
EOF

# =========================
# components/Icon.tsx
# =========================
cat > $COMP_DIR/Icon.tsx <<'EOF'
import React from "react";
import * as Icons from "@mui/icons-material";

// Универсальная обёртка для MUI-иконок (имена задаём в CONFIG.icons)
export default function Icon({ name, size = 24 }: { name: string; size?: number }) {
  const Cmp = (Icons as any)[name];
  if (!Cmp) return <span className="icon-missing">{name}</span>;
  return <Cmp style={{ fontSize: size }} />;
}
EOF

# =========================
# components/Avatar.tsx
# =========================
cat > $COMP_DIR/Avatar.tsx <<'EOF'
import React from "react";
import { CONFIG } from "../config";

export default function Avatar({ src, size = 32 }: { src?: string; size?: number }) {
  return (
    <img
      src={src || CONFIG.assets.avatar}
      alt="avatar"
      style={{ width: size, height: size }}
      className="avatar"
    />
  );
}
EOF

# =========================
# components/MediaGrid.tsx
# =========================
cat > $COMP_DIR/MediaGrid.tsx <<'EOF'
import React from "react";

export default function MediaGrid({ photos }: { photos?: string[] }) {
  if (!photos?.length) return null;
  return (
    <div className="media-grid">
      {photos.map((src, i) => (
        <img key={i} src={src} alt={`media-${i}`} />
      ))}
    </div>
  );
}
EOF

# =========================
# components/PointPinCard.tsx
# =========================
cat > $COMP_DIR/PointPinCard.tsx <<'EOF'
import React from "react";
import { useNavigate } from "react-router-dom";
import { Place } from "../types";
import MediaGrid from "./MediaGrid";

export default function PointPinCard({ place }: { place: Place }) {
  const navigate = useNavigate();
  return (
    <div className="pin-card" onClick={() => navigate(`/place/${place.id}`)}>
      <h3>{place.name}</h3>
      <MediaGrid photos={place.photos} />
    </div>
  );
}
EOF

# =========================
# pages/MapScreen.tsx — карта + пины по типам + bbox-фетч + дебаунс + URL-состояние
# =========================
cat > $PAGES_DIR/MapScreen.tsx <<'EOF'
import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from "react-leaflet";
import L, { LatLngBounds } from "leaflet";
import { API } from "../api";
import { Place } from "../types";
import { useNavigate, useSearchParams } from "react-router-dom";
import { CONFIG } from "../config";

// простая утилита дебаунса
function debounce<T extends (...args: any[]) => void>(fn: T, ms: number) {
  let t: any;
  return (...args: Parameters<T>) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
}

// Кастомный компонент, слушает перемещения карты и вызывает onBBox
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

// Фабрика иконок пинов по типу
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
        const data = await API.points(bbox, 500);
        cacheRef.current = { bboxKey: key, data };
        setPoints(data);
      } catch (e) {
        console.error("points load error", e);
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

  // Первичная загрузка: чуть увеличенный bbox вокруг стартовой точки
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

  // Синхроним положение карты в URL (при открытии попапов и кликах это не мешает)
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
        {points.map((p) => (
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
EOF

# =========================
# Заглушки/простые страницы (остальные)
# =========================
cat > $PAGES_DIR/FeedScreen.tsx <<'EOF'
import React, { useEffect, useState } from "react";
import { API } from "../api";
import Icon from "../components/Icon";
import { CONFIG } from "../config";

export default function FeedScreen() {
  const [items, setItems] = useState<any[]>([]);
  const [offset, setOffset] = useState(0);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    load();
    // eslint-disable-next-line
  }, []);

  const load = async () => {
    if (busy) return;
    setBusy(true);
    try {
      const data = await API.feed(10, offset);
      setItems((s) => [...s, ...data]);
      setOffset((o) => o + 10);
    } catch (e) {
      console.error(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="page">
      <h2>Лента</h2>
      {items.map((it) => (
        <div className="card" key={it.id}>
          <div className="row">
            <strong>{it.user_name || "Рыбак"}</strong>
            <span className="muted">{new Date(it.created_at).toLocaleString()}</span>
          </div>
          <div className="row">
            <span>{it.species}</span>
          </div>
          {it.media_url && <img src={it.media_url} alt="" className="w100" />}
          <div className="row actions">
            <span><Icon name={CONFIG.icons.like} /> {it.likes_count ?? 0}</span>
            <span><Icon name={CONFIG.icons.comment} /> {it.comments_count ?? 0}</span>
            <span><Icon name={CONFIG.icons.share} /></span>
          </div>
        </div>
      ))}
      <div className="center">
        <button onClick={load} disabled={busy} className="btn">
          {busy ? "Загрузка..." : "Ещё"}
        </button>
      </div>
    </div>
  );
}
EOF

for page in CatchDetailPage AddCatchPage AddPlacePage NotificationsPage ProfilePage WeatherPage PlaceDetailPage; do
cat > $PAGES_DIR/${page}.tsx <<EOF
import React from "react";
export default function ${page}() {
  return <div className="page"><h2>${page}</h2><p>Страница в разработке.</p></div>;
}
EOF
done

# =========================
# styles/app.css
# =========================
cat > $STYLES_DIR/app.css <<'EOF'
:root{
  --header-h:56px;
  --bottom-h:64px;
  --bg:#f7f7fa;
  --text:#111;
  --muted:#666;
  --card:#fff;
  --border:#e6e6ee;
}

*{box-sizing:border-box}
html,body,#root{height:100%}
body{margin:0;font-family:system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,'Helvetica Neue',Arial;color:var(--text);background:var(--bg)}

.app-container{min-height:100%;display:flex;flex-direction:column}
.app-header{height:var(--header-h);display:flex;align-items:center;justify-content:space-between;padding:0 12px;background:#fff;border-bottom:1px solid var(--border);background-size:cover;background-position:center}
.app-header .logo{height:34px;cursor:pointer}
.app-header .right{display:flex;gap:12px;align-items:center}
.header-link{display:flex;gap:6px;align-items:center;color:inherit;text-decoration:none;position:relative}
.header-link .badge{position:absolute;top:-6px;right:-6px;font-size:10px;color:#f44}
.avatar{width:32px;height:32px;border-radius:50%;object-fit:cover}

.app-main{flex:1;min-height:0;padding-bottom:var(--bottom-h)}
.page{max-width:780px;margin:0 auto;padding:16px}
.center{text-align:center}
.btn{background:#111;color:#fff;border:0;border-radius:10px;padding:10px 16px;cursor:pointer}
.btn:disabled{opacity:.6;cursor:default}
.muted{color:var(--muted)}

.card{background:var(--card);border:1px solid var(--border);border-radius:16px;padding:12px;margin-bottom:12px}
.row{display:flex;gap:10px;align-items:center;justify-content:space-between}
.w100{width:100%;border-radius:12px}

.bottom-nav{position:fixed;left:0;right:0;bottom:0;height:var(--bottom-h);background:#fff;border-top:1px solid var(--border);display:flex;justify-content:space-around;align-items:center;z-index:1100}
.bn-item{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;color:#333;text-decoration:none;font-size:12px;height:100%}
.bn-item.active{color:#111;font-weight:600}

.map-page{position:fixed;inset:var(--header-h) 0 var(--bottom-h) 0}
.leaflet-container{height:100%;width:100%}
.map-loader{position:absolute;right:8px;top:8px;background:#fff;border:1px solid var(--border);border-radius:10px;padding:6px 10px;z-index:1200}

.popup-card{cursor:pointer;max-width:220px}
.popup-title{display:flex;align-items:center;gap:6px;margin-bottom:6px}
.popup-type{font-size:12px;color:#555;background:#f0f0f5;padding:2px 6px;border-radius:999px}
.popup-photo{width:100%;border-radius:8px;margin-top:6px}
.popup-link{margin-top:6px;color:#0a6efe;font-size:13px}

.media-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:4px}
.media-grid img{width:100%;height:90px;object-fit:cover;border-radius:8px}

.hide-sm{display:none}
@media (min-width:680px){ .hide-sm{display:inline} }
EOF

echo "✅ Готово! Файлы созданы/обновлены."
echo "Проверь, что установлены зависимости: react, react-dom, react-router-dom, leaflet, react-leaflet, @mui/icons-material"
echo "Пример: npm i react react-dom react-router-dom leaflet react-leaflet @mui/material @mui/icons-material"