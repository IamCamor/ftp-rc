#!/usr/bin/env bash
set -euo pipefail

FRONTEND_DIR="frontend"
SRC="$FRONTEND_DIR/src"

[ -d "$SRC" ] || { echo "❌ Не найден каталог $SRC (запусти из корня проекта)"; exit 1; }

mkdir -p "$SRC/utils" "$SRC/components" "$SRC/pages" "$SRC/styles"

#####################################
# 1) config.ts — именованный и дефолтный экспорт
#####################################
cat > "$SRC/config.ts" <<'TS'
export type AppConfig = {
  apiBase: string;
  assets: {
    logo: string;
    defaultAvatar: string;
    bgPattern?: string;
  };
  icons?: Record<string,string>;
};

export const config: AppConfig = {
  apiBase: 'https://api.fishtrackpro.ru/api/v1',
  assets: {
    logo: '/logo.svg',
    defaultAvatar: '/default-avatar.png',
    bgPattern: '/bg-pattern.png',
  },
  icons: {
    feed: 'home',
    map: 'map',
    add: 'add_circle',
    alerts: 'notifications',
    profile: 'person',
    weather: 'cloud',
    like: 'favorite',
    comment: 'chat_bubble',
    share: 'ios_share',
    back: 'arrow_back',
  }
};

export default config;
TS

#####################################
# 2) styles/app.css — glassmorphism + карта
#####################################
cat > "$SRC/styles/app.css" <<'CSS'
:root{
  --bg: #0b1220;
  --fg: #e7eefc;
  --muted: #b6c0d8;
  --glass-bg: rgba(255,255,255,0.08);
  --glass-brd: rgba(255,255,255,0.16);
  --accent: #56b3ff;
}

*{box-sizing:border-box}
html,body,#root{height:100%}
body{margin:0;background:radial-gradient(1200px 800px at 80% -200px, rgba(86,179,255,0.12), transparent), var(--bg); color:var(--fg); font:14px/1.4 system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif;}

a{color:inherit;text-decoration:none}
.container{max-width:1200px;margin:0 auto;padding:16px}

.glass{
  background: var(--glass-bg);
  border: 1px solid var(--glass-brd);
  box-shadow: 0 10px 30px rgba(0,0,0,.25);
  backdrop-filter: blur(14px) saturate(120%);
  -webkit-backdrop-filter: blur(14px) saturate(120%);
  border-radius: 16px;
}

.header-glass{position:sticky;top:0;z-index:30}
.footer-glass{position:sticky;bottom:0;z-index:25}

.btn{
  display:inline-flex;align-items:center;gap:8px;
  padding:10px 14px;border-radius:12px;border:1px solid var(--glass-brd);
  background: var(--glass-bg);color:var(--fg);cursor:pointer;
}
.btn:hover{background: rgba(255,255,255,0.12)}
.fab{
  position:fixed;right:16px;bottom:16px;z-index:40;
  display:flex;flex-direction:column;gap:12px;
}
.fab .btn{border-radius:16px}

.card{padding:12px;border-radius:16px}
.card+.card{margin-top:12px}

/* Карта */
.map-wrap{position:relative;height:calc(100vh - 120px);margin:12px}
#map{height:100%;width:100%;border-radius:16px;overflow:hidden}
.leaflet-control-attribution, .leaflet-control-zoom{filter: drop-shadow(0 2px 6px rgba(0,0,0,.4));}

/* Хлебные крошки/подзаголовок */
.subtle{color:var(--muted)}

/* Медиа-сетка для карточек */
.media-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:6px}
.media-grid img{width:100%;height:100px;object-fit:cover;border-radius:10px}

/* Топ-бар и низ меню */
.header-bar, .bottom-bar{display:flex;align-items:center;justify-content:space-between;padding:10px 12px}
.nav-row{display:flex;gap:8px}
.nav-link{display:flex;flex-direction:column;align-items:center;font-size:12px;color:var(--muted)}
.nav-link.active{color:var(--fg)}
.icon{font-family: 'Material Symbols Rounded'; font-weight: normal; font-style: normal; font-size: 22px; line-height: 1; display:inline-block; text-transform: none; letter-spacing: normal; white-space: nowrap; direction: ltr; -webkit-font-feature-settings: 'liga'; -webkit-font-smoothing: antialiased;}

/* Header бренд */
.brand{display:flex;align-items:center;gap:10px}
.brand img{height:28px;width:auto;display:block}
.brand .title{font-weight:600;letter-spacing:.2px}
CSS

#####################################
# 3) utils/leafletLoader.ts — подгружаем Leaflet с CDN на лету
#####################################
cat > "$SRC/utils/leafletLoader.ts" <<'TS'
let promise: Promise<typeof window.L> | null = null;

export function loadLeaflet(): Promise<typeof window.L> {
  if (typeof window === 'undefined') return Promise.reject(new Error('no window'));
  if ((window as any).L) return Promise.resolve((window as any).L);

  if (promise) return promise;

  promise = new Promise((resolve, reject) => {
    const css = document.createElement('link');
    css.rel = 'stylesheet';
    css.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
    css.integrity = 'sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=';
    css.crossOrigin = '';
    document.head.appendChild(css);

    const s = document.createElement('script');
    s.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
    s.integrity = 'sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=';
    s.crossOrigin = '';
    s.onload = () => resolve((window as any).L);
    s.onerror = () => reject(new Error('Leaflet load error'));
    document.head.appendChild(s);
  });

  return promise;
}
TS

#####################################
# 4) components/Header.tsx — glass + ссылка на погоду, счётчик бонусов
#####################################
cat > "$SRC/components/Header.tsx" <<'TS'
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';

type HeaderProps = { bonuses?: number };

const Header: React.FC<HeaderProps> = ({ bonuses = 0 }) => {
  const { pathname } = useLocation();
  const onWeather = ['/weather'].includes(pathname);

  return (
    <header className="glass header-glass">
      <div className="header-bar">
        <div className="brand">
          <img src={config.assets.logo} alt="logo"/>
          <span className="title">FishTrack Pro</span>
        </div>
        <div className="nav-row">
          <Link to="/weather" className={`btn ${onWeather ? 'active' : ''}`} title="Погода">
            <span className="icon">cloud</span>
            <span>Погода</span>
          </Link>
          <Link to="/alerts" className="btn" title="Уведомления">
            <span className="icon">notifications</span>
          </Link>
          <Link to="/profile" className="btn" title="Профиль">
            <span className="icon">person</span>
            <span style={{marginLeft:4}}>{bonuses}</span>
          </Link>
        </div>
      </div>
    </header>
  );
};

export default Header;
export { Header };
TS

#####################################
# 5) components/BottomNav.tsx — glass + нормальные иконки
#####################################
cat > "$SRC/components/BottomNav.tsx" <<'TS'
import React from 'react';
import { NavLink } from 'react-router-dom';

const Item: React.FC<{to:string; icon:string; label:string}> = ({to, icon, label}) => (
  <NavLink to={to} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
    <span className="icon">{icon}</span>
    <span>{label}</span>
  </NavLink>
);

const BottomNav: React.FC = () => {
  return (
    <nav className="glass footer-glass">
      <div className="bottom-bar" style={{justifyContent:'space-around'}}>
        <Item to="/feed" icon="home" label="Лента"/>
        <Item to="/map" icon="map" label="Карта"/>
        <Item to="/add/catch" icon="add_circle" label="Улов"/>
        <Item to="/alerts" icon="notifications" label="Оповещения"/>
        <Item to="/profile" icon="person" label="Профиль"/>
      </div>
    </nav>
  );
};

export default BottomNav;
export { BottomNav };
TS

#####################################
# 6) components/PointPinCard.tsx — карточка пина c изображением и ссылкой
#####################################
cat > "$SRC/components/PointPinCard.tsx" <<'TS'
import React from 'react';
import { Link } from 'react-router-dom';

type Props = {
  id: string|number;
  type?: 'place'|'catch';
  title?: string;
  photos?: string[];
};

const PointPinCard: React.FC<Props> = ({ id, type='place', title='Точка', photos=[] }) => {
  const href = type === 'catch' ? `/catch/${id}` : `/place/${id}`;
  const img = photos[0];
  return (
    <div className="glass card" style={{minWidth:220}}>
      {img && <img src={img} alt={title} style={{width:'100%',height:140,objectFit:'cover',borderRadius:12,marginBottom:8}}/>}
      <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',gap:8}}>
        <div>
          <div style={{fontWeight:600}}>{title}</div>
          <div className="subtle">{type === 'catch' ? 'Улов' : 'Место'}</div>
        </div>
        <Link to={href} className="btn">Открыть</Link>
      </div>
    </div>
  );
};
export default PointPinCard;
TS

#####################################
# 7) pages/MapScreen.tsx — рабочая карта (Leaflet CDN), пины из API, FAB
#####################################
cat > "$SRC/pages/MapScreen.tsx" <<'TS'
import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { points, saveWeatherFav } from '../api';
import type { Point } from '../types';
import { loadLeaflet } from '../utils/leafletLoader';

const DEFAULT_CENTER: [number, number] = [55.75, 37.61]; // Москва
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
        L.tileLayer(
          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          { maxZoom: 19, attribution: '&copy; OpenStreetMap' }
        ).addTo(map);
        mapRef.current = map;
        setReady(true);

        // Click to add temp marker and offer actions
        map.on('click', async (e: any) => {
          const lat = e.latlng.lat, lng = e.latlng.lng;
          const m = L.marker([lat,lng]).addTo(map);
          m.bindPopup(`
            <div style="padding:6px;min-width:180px">
              <b>Новая точка</b><br/>
              ${lat.toFixed(5)}, ${lng.toFixed(5)}<br/><br/>
              <button id="addPlaceBtn" style="padding:6px 10px;border-radius:8px;border:1px solid #fff3;background:#ffffff14;color:#fff">Добавить место</button>
              <button id="saveWeatherBtn" style="padding:6px 10px;border-radius:8px;border:1px solid #fff3;background:#ffffff14;color:#fff;margin-left:6px">В погоду</button>
            </div>
          `).openPopup();

          setTimeout(() => {
            const addPlaceBtn = document.getElementById('addPlaceBtn');
            const saveWeatherBtn = document.getElementById('saveWeatherBtn');
            addPlaceBtn?.addEventListener('click', () => nav(`/add/place?lat=${lat}&lng=${lng}`));
            saveWeatherBtn?.addEventListener('click', async () => {
              await saveWeatherFav({ lat, lng, name: `Точка ${lat.toFixed(3)},${lng.toFixed(3)}` });
              alert('Сохранено в избранные точки погоды');
            });
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
        const bbox = null; // можно вычислять из mapRef.current.getBounds()
        const list: Point[] = await points({ limit: 500, bbox: undefined });
        list.forEach(p => {
          const m = L.marker([p.lat, p.lng]).addTo(mapRef.current);
          const img = (p.media && p.media[0]) || p.photo_url || '';
          const safeTitle = (p.title || p.species || 'Точка').replace(/</g,'&lt;').replace(/>/g,'&gt;');
          const card = `
            <div style="min-width:220px">
              ${img ? `<img src="${img}" style="width:100%;height:120px;object-fit:cover;border-radius:10px;margin-bottom:6px" />` : ''}
              <div style="font-weight:600;margin-bottom:6px">${safeTitle}</div>
              <div style="display:flex;gap:6px">
                <a href="${p.type==='catch'?`/catch/${p.id}`:`/place/${p.id}`}" class="leaflet-popup-link" data-id="${p.id}">Открыть</a>
              </div>
            </div>`;
          m.bindPopup(card);
          m.on('popupopen', () => {
            // Навигация без перезагрузки
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

#####################################
# 8) Подключаем Google Material Symbols (иконки) в index.html, если ещё не
#####################################
INDEX_HTML="$FRONTEND_DIR/index.html"
if [ -f "$INDEX_HTML" ] && ! grep -q "Material Symbols" "$INDEX_HTML"; then
  TMP="$(mktemp)"
  awk '
    /<\/head>/ && !done {
      print "  <link href=\"https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:FILL,GRAD,opsz,wght@0,0,24,400\" rel=\"stylesheet\">";
      done=1
    }
    { print }
  ' "$INDEX_HTML" > "$TMP"
  mv "$TMP" "$INDEX_HTML"
  echo "🔤 Подключён шрифт Material Symbols в index.html"
fi

#####################################
# 9) Импорт стилей в main.tsx (если ещё не)
#####################################
if [ -f "$SRC/main.tsx" ] && ! grep -q "styles/app.css" "$SRC/main.tsx"; then
  TMP="$(mktemp)"
  echo "import './styles/app.css';" > "$TMP"
  cat "$SRC/main.tsx" >> "$TMP"
  mv "$TMP" "$SRC/main.tsx"
  echo "🎨 Подключён styles/app.css в main.tsx"
fi

echo "✅ Готово. Запусти:"
echo "   cd $FRONTEND_DIR && npm run dev"
echo "и проверь: карта отображается, пины грузятся, glass-оформление видно."