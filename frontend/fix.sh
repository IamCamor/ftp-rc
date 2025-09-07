#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
SRC="$ROOT/src"
[ -d "$ROOT/frontend/src" ] && SRC="$ROOT/frontend/src"

mkdir -p "$SRC/components" "$SRC/layouts" "$SRC/styles" "$SRC/utils"

###############################################################################
# config.ts – единая точка правды
###############################################################################
cat > "$SRC/config.ts" <<'TS'
type IconsConfig = {
  // имена для Material Symbols Rounded
  logo?: string;
  weather?: string;
  bell?: string;
  add?: string;
  map?: string;
  feed?: string;
  profile?: string;
  like?: string;
  comment?: string;
  share?: string;
};

type FeatureFlags = {
  auth: {
    local: boolean;
    oauthGoogle: boolean;
    oauthVk: boolean;
    oauthYandex: boolean;
    oauthApple: boolean;
    requireAgreementOnSignup: boolean;
  };
  ui: {
    glass: boolean;
    showWeatherLinkInHeader: boolean;
  };
  weather: {
    allowSavePoint: boolean;
    requireAuthForWeatherSave: boolean;
  };
};

export type AppConfig = {
  appName: string;
  apiBase: string;   // e.g. https://api.fishtrackpro.ru/api/v1
  authBase: string;  // e.g. https://api.fishtrackpro.ru
  legal: {
    termsUrl: string;
    privacyUrl: string;
    offerUrl: string;
  };
  assets: {
    logoUrl: string;
    defaultAvatar: string;
    bgPattern?: string;
  };
  icons: IconsConfig;
  features: FeatureFlags;
};

// ❗ Отредактируйте при необходимости URL-ы для прод/стейдж:
const config: AppConfig = {
  appName: "FishTrack Pro",
  apiBase: (typeof window !== 'undefined'
    ? (window as any).__API_BASE__
    : "") || "https://api.fishtrackpro.ru/api/v1",
  authBase: (typeof window !== 'undefined'
    ? (window as any).__AUTH_BASE__
    : "") || "https://api.fishtrackpro.ru",

  legal: {
    termsUrl: "https://www.fishtrackpro.ru/legal/terms",
    privacyUrl: "https://www.fishtrackpro.ru/legal/privacy",
    offerUrl: "https://www.fishtrackpro.ru/legal/offer",
  },

  assets: {
    logoUrl: "/static/logo.svg",
    defaultAvatar: "/static/default-avatar.png",
    bgPattern: "/static/pattern.png",
  },

  icons: {
    logo: "waves",
    weather: "partly_cloudy_day",
    bell: "notifications",
    add: "add",
    map: "map",
    feed: "dynamic_feed",
    profile: "account_circle",
    like: "favorite",
    comment: "chat",
    share: "share",
  },

  features: {
    auth: {
      local: true,
      oauthGoogle: true,
      oauthVk: true,
      oauthYandex: true,
      oauthApple: true,
      requireAgreementOnSignup: true,
    },
    ui: {
      glass: true,
      showWeatherLinkInHeader: true,
    },
    weather: {
      allowSavePoint: true,
      requireAuthForWeatherSave: true,
    },
  },
};

export default config;
TS

###############################################################################
# styles/app.css – базовый glass + утилиты
###############################################################################
cat > "$SRC/styles/app.css" <<'CSS'
:root{
  --blur: 12px;
  --glass-bg: rgba(255,255,255,0.08);
  --glass-bd: rgba(255,255,255,0.18);
  --glass-shadow: 0 10px 30px rgba(0,0,0,0.25);
}

*{box-sizing:border-box}
html,body,#root{height:100%}
body{
  margin:0;
  font-family: system-ui, -apple-system, Segoe UI, Roboto, "Helvetica Neue", Arial, "Noto Sans", "Apple Color Emoji","Segoe UI Emoji";
  color:#fff;
  background: radial-gradient(1200px 600px at 80% -10%, rgba(90,170,255,.15), transparent 60%),
              radial-gradient(800px 800px at -10% 120%, rgba(0,255,170,.10), transparent 60%),
              #0b1220;
  background-attachment: fixed;
}

a{ color: inherit; text-decoration: none; }

.glass{
  backdrop-filter: blur(var(--blur));
  -webkit-backdrop-filter: blur(var(--blur));
  background: var(--glass-bg);
  border: 1px solid var(--glass-bd);
  box-shadow: var(--glass-shadow);
  border-radius: 16px;
}

.header{
  position: sticky; top: 0; z-index: 10;
  padding: 10px 14px;
  display:flex; align-items:center; gap:12px;
}

.header__spacer{ flex:1 }

.bottom-nav{
  position: sticky; bottom: 0; z-index: 10;
  padding: 8px 10px;
  display:flex; align-items:center; justify-content: space-around;
}

.icon-btn{
  display:inline-flex; gap:8px; align-items:center; padding:8px 12px;
  border-radius: 12px;
}

.material-symbols-rounded{
  font-variation-settings: 
    "FILL" 0,
    "wght" 400,
    "GRAD" 0,
    "opsz" 24;
  font-size: 22px;
  line-height:1;
  vertical-align: middle;
}

.main-wrap{
  min-height: calc(100dvh - 120px);
  padding: 12px;
}
CSS

###############################################################################
# utils: подключение Material Symbols из кода
###############################################################################
cat > "$SRC/utils/fonts.ts" <<'TS'
let injected = false;

export function ensureMaterialSymbols() {
  if (injected || typeof document === 'undefined') return;
  const id = 'material-symbols-rounded-link';
  if (document.getElementById(id)) { injected = true; return; }
  const link = document.createElement('link');
  link.id = id;
  link.rel = 'stylesheet';
  // порядок осей: FILL,wght,GRAD,opsz – строго алфавитно
  link.href = 'https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:FILL,wght,GRAD,opsz@0,400,0,24';
  document.head.appendChild(link);
  injected = true;
}
TS

###############################################################################
# components/Icon.tsx – универсальная иконка
###############################################################################
cat > "$SRC/components/Icon.tsx" <<'TS'
import React from 'react';

type IconProps = {
  name: string;       // имя из Material Symbols
  className?: string;
  title?: string;
  size?: number;      // px
  fill?: 0|1;
  weight?: 100|200|300|400|500|600|700;
};

const Icon: React.FC<IconProps> = ({ name, className, title, size = 22, fill = 0, weight = 400 }) => {
  const style: React.CSSProperties = {
    fontVariationSettings: `"FILL" ${fill}, "wght" ${weight}, "GRAD" 0, "opsz" 24`,
    fontSize: size,
  };
  return (
    <span className={`material-symbols-rounded ${className||''}`} style={style} aria-label={title||name}>
      {name}
    </span>
  );
};

export default Icon;
TS

###############################################################################
# components/Header.tsx – шапка
###############################################################################
cat > "$SRC/components/Header.tsx" <<'TS'
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';
import Icon from './Icon';

type HeaderProps = {
  title?: string;
};

const Header: React.FC<HeaderProps> = ({ title }) => {
  const loc = useLocation();

  return (
    <header className="header glass" role="banner" aria-label="main header">
      <Link to="/" className="icon-btn" aria-label="home">
        <Icon name={config.icons.logo || 'waves'} size={24} />
        <strong>{config.appName}</strong>
      </Link>

      <div className="header__spacer" />

      {config.features.ui.showWeatherLinkInHeader && (
        <Link to="/weather" className="icon-btn" aria-label="weather link">
          <Icon name={config.icons.weather || 'partly_cloudy_day'} />
        </Link>
      )}

      <Link to="/alerts" className="icon-btn" aria-label="notifications link">
        <Icon name={config.icons.bell || 'notifications'} />
      </Link>

      <Link to="/profile" className="icon-btn" aria-label="profile link">
        <Icon name={config.icons.profile || 'account_circle'} />
      </Link>
    </header>
  );
};

export default Header;
TS

###############################################################################
# components/BottomNav.tsx – нижнее меню
###############################################################################
cat > "$SRC/components/BottomNav.tsx" <<'TS'
import React from 'react';
import { NavLink } from 'react-router-dom';
import Icon from './Icon';
import config from '../config';

const cls = (isActive:boolean) =>
  `icon-btn ${isActive ? 'glass' : ''}`;

const BottomNav: React.FC = () => {
  return (
    <nav className="bottom-nav glass" role="navigation" aria-label="bottom navigation">
      <NavLink to="/" className={({isActive}) => cls(isActive)} aria-label="feed">
        <Icon name={config.icons.feed || 'dynamic_feed'} />
      </NavLink>

      <NavLink to="/map" className={({isActive}) => cls(isActive)} aria-label="map">
        <Icon name={config.icons.map || 'map'} />
      </NavLink>

      <NavLink to="/add/catch" className={({isActive}) => cls(isActive)} aria-label="add catch">
        <Icon name={config.icons.add || 'add'} />
      </NavLink>

      <NavLink to="/alerts" className={({isActive}) => cls(isActive)} aria-label="alerts">
        <Icon name={config.icons.bell || 'notifications'} />
      </NavLink>

      <NavLink to="/profile" className={({isActive}) => cls(isActive)} aria-label="profile">
        <Icon name={config.icons.profile || 'account_circle'} />
      </NavLink>
    </nav>
  );
};

export default BottomNav;
TS

###############################################################################
# layouts/AppLayout.tsx – универсальный каркас
###############################################################################
cat > "$SRC/layouts/AppLayout.tsx" <<'TS'
import React from 'react';
import Header from '../components/Header';
import BottomNav from '../components/BottomNav';

type Props = {
  children: React.ReactNode;
};

const AppLayout: React.FC<Props> = ({ children }) => {
  return (
    <div>
      <Header />
      <main className="main-wrap">
        {children}
      </main>
      <BottomNav />
    </div>
  );
};

export default AppLayout;
TS

###############################################################################
# AppRoot.tsx – маршруты с «умным» lazy
###############################################################################
cat > "$SRC/AppRoot.tsx" <<'TS'
import React, { Suspense, lazy } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import AppLayout from './layouts/AppLayout';

// утилита: поддержка default ИЛИ именованных экспортов
function smartLazy<T = any>(path: string, named?: string) {
  return lazy(async () => {
    const m: any = await import(/* @vite-ignore */ path);
    const picked = m?.default ?? (named ? m[named] : undefined) ?? Object.values(m).find((v:any)=> typeof v === 'function') ?? (()=>null);
    return { default: picked };
  });
}

// страницы (не трогаем ваши файлы — просто подхватываем что есть)
const FeedScreen         = smartLazy('./pages/FeedScreen', 'FeedScreen');
const MapScreen          = smartLazy('./pages/MapScreen', 'MapScreen');
const AddCatchPage       = smartLazy('./pages/AddCatchPage', 'AddCatchPage');
const AddPlacePage       = smartLazy('./pages/AddPlacePage', 'AddPlacePage');
const NotificationsPage  = smartLazy('./pages/NotificationsPage', 'NotificationsPage');
const ProfilePage        = smartLazy('./pages/ProfilePage', 'ProfilePage');
const WeatherPage        = smartLazy('./pages/WeatherPage', 'WeatherPage');
const CatchDetailPage    = smartLazy('./pages/CatchDetailPage', 'CatchDetailPage');
const PlaceDetailPage    = smartLazy('./pages/PlaceDetailPage', 'PlaceDetailPage');

const Fallback: React.FC = () => (
  <div className="glass" style={{padding:16}}>Загрузка…</div>
);

const AppRoot: React.FC = () => {
  return (
    <BrowserRouter>
      <AppLayout>
        <Suspense fallback={<Fallback/>}>
          <Routes>
            <Route path="/" element={<FeedScreen/>} />
            <Route path="/map" element={<MapScreen/>} />
            <Route path="/add/catch" element={<AddCatchPage/>} />
            <Route path="/add/place" element={<AddPlacePage/>} />
            <Route path="/alerts" element={<NotificationsPage/>} />
            <Route path="/profile" element={<ProfilePage/>} />
            <Route path="/weather" element={<WeatherPage/>} />
            <Route path="/catch/:id" element={<CatchDetailPage/>} />
            <Route path="/place/:id" element={<PlaceDetailPage/>} />
            <Route path="*" element={<div className="glass" style={{padding:16}}>Страница не найдена</div>} />
          </Routes>
        </Suspense>
      </AppLayout>
    </BrowserRouter>
  );
};

export default AppRoot;
TS

###############################################################################
# App.tsx – базовый провайдер
###############################################################################
cat > "$SRC/App.tsx" <<'TS'
import React from 'react';
import './styles/app.css';
import AppRoot from './AppRoot';

const App: React.FC = () => {
  return <AppRoot />;
};

export default App;
TS

###############################################################################
# main.tsx – монтирование + подключение шрифта + лог ошибок регистрации
###############################################################################
cat > "$SRC/main.tsx" <<'TS'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import { ensureMaterialSymbols } from './utils/fonts';

ensureMaterialSymbols();

const el = document.getElementById('root');
if (!el) {
  const e = document.createElement('div');
  e.id = 'root';
  document.body.appendChild(e);
}

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

console.log('[boot] App mounted');

// global handler — чтобы «Failed to fetch» показывался понятно
window.addEventListener('unhandledrejection', (ev) => {
  const r = ev.reason;
  const msg = (r && (r.message || r.toString())) || 'Network error';
  if (String(msg).includes('Failed to fetch')) {
    console.warn('[network] Вероятно, сеть/CORS/backend:', msg);
  }
});
TS

echo "✅ Каркас навигации и дизайн обновлены."
echo "Теперь: npm run build && npm run preview  (или ваш дев-сервер)"