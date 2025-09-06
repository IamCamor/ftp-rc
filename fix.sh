#!/usr/bin/env bash
set -euo pipefail

FRONTEND_DIR="frontend"
SRC="$FRONTEND_DIR/src"
SHIMS="$SRC/shims"
SAFETY="$SRC/safety"

[ -d "$SRC" ] || { echo "❌ Not found: $SRC"; exit 1; }

mkdir -p "$SHIMS" "$SAFETY"

############################################
# 1) ErrorBoundary + мини-диаг панель
############################################
cat > "$SAFETY/ErrorBoundary.tsx" <<'TSX'
import React from 'react';

type Props = { children: React.ReactNode };
type State = { error: any };

export default class ErrorBoundary extends React.Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: any) {
    return { error };
  }

  componentDidCatch(error: any, info: any) {
    // лог в консоль
    console.error('[ErrorBoundary]', error, info);
    (window as any).__FTP_LAST_ERROR__ = { error, info };
  }

  render() {
    if (this.state.error) {
      return (
        <div style={{padding:16,fontFamily:'system-ui,-apple-system,Segoe UI,Roboto',color:'#fff',
          background:'linear-gradient(135deg,rgba(20,20,30,.7),rgba(20,20,30,.5))',backdropFilter:'blur(10px)',minHeight:'100vh'}}>
          <h2 style={{margin:'8px 0'}}>Упс, что-то пошло не так</h2>
          <pre style={{whiteSpace:'pre-wrap',background:'rgba(0,0,0,.2)',padding:12,borderRadius:8}}>
{String(this.state.error?.message || this.state.error)}
          </pre>
          <p>Откройте консоль браузера — там подробности. Временная заглушка показывает оболочку приложения.</p>
          <button onClick={()=>location.reload()} style={{marginTop:12,padding:'8px 12px',borderRadius:8}}>Перезагрузить</button>
        </div>
      );
    }
    return this.props.children;
  }
}

// Диаг-панель по ?diag=1
(function(){
  try {
    const u=new URL(window.location.href);
    if(u.searchParams.get('diag')==='1'){
      const box=document.createElement('div');
      box.style.cssText='position:fixed;bottom:10px;right:10px;z-index:99999;background:rgba(0,0,0,.75);color:#0f0;font:12px/1.4 monospace;padding:10px;border-radius:8px;max-width:40vw;max-height:40vh;overflow:auto';
      const log=(...a:any[])=>{ const p=document.createElement('div'); p.textContent=a.map(x=>typeof x==='object'?JSON.stringify(x):String(x)).join(' '); box.appendChild(p); };
      (window as any).__FTP_DIAG_LOG__ = log;
      log('diag=1 enabled');
      log('build time:', String((import.meta as any).env?.VITE_BUILD_TIME||'n/a'));
      document.body.appendChild(box);
      window.addEventListener('error',e=>log('win.error:',e.message));
      window.addEventListener('unhandledrejection',(e:any)=>log('unhandledrejection', e?.reason));
    }
  } catch {}
})();
TSX

############################################
# 2) Универсальный «шим» генератор
############################################
make_shim () {
  local target="$1" ; local exportName="$2"
  cat > "$SHIMS/$exportName.tsx" <<TSX
import * as M from '$target';
import React from 'react';
const pick = (mod: any): any =>
  mod?.default ??
  mod?.${exportName} ??
  Object.values(mod || {}).find((v:any)=> typeof v==='function' || (v && typeof v==='object' && 'props' in v)) ??
  (() => <div style={{padding:16}}>⚠️ Не найден экспорт для <b>${exportName}</b> из <code>${target}</code></div>);
const C: any = pick(M);
export default C;
TSX
}

# Компоненты
make_shim '../components/Header' 'Header'
make_shim '../components/BottomNav' 'BottomNav'

# Страницы
make_shim '../pages/FeedScreen' 'FeedScreen'
make_shim '../pages/MapScreen' 'MapScreen'
make_shim '../pages/AddCatchPage' 'AddCatchPage'
make_shim '../pages/AddPlacePage' 'AddPlacePage'
make_shim '../pages/NotificationsPage' 'NotificationsPage'
make_shim '../pages/ProfilePage' 'ProfilePage'
make_shim '../pages/WeatherPage' 'WeatherPage'
make_shim '../pages/CatchDetailPage' 'CatchDetailPage'
make_shim '../pages/PlaceDetailPage' 'PlaceDetailPage'

############################################
# 3) Безопасный AppRoot (Router + каркас)
############################################
cat > "$SRC/AppRoot.tsx" <<'TSX'
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import ErrorBoundary from './safety/ErrorBoundary';

// Шапка / низ — через шимы, чтобы не падать, если нет default экспорта
import Header from './shims/Header';
import BottomNav from './shims/BottomNav';

// Страницы
import FeedScreen from './shims/Feed';
import MapScreen from './shims/Map';
import AddCatchPage from './shims/AddCatch';
import AddPlacePage from './shims/AddPlace';
import NotificationsPage from './shims/Alerts';
import ProfilePage from './shims/Profile';
import WeatherPage from './shims/Weather';
import CatchDetailPage from './shims/CatchDetail';
import PlaceDetailPage from './shims/PlaceDetail';

const Shell: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <div style={{minHeight:'100vh',background:'radial-gradient(1200px 800px at 20% -10%,rgba(255,255,255,.18),transparent),linear-gradient( to bottom right, rgba(30,30,45,.85), rgba(12,14,20,.95))', backdropFilter:'blur(12px)'}}>
    <Header />
    <main style={{padding:'12px 12px 72px'}}>{children}</main>
    <BottomNav />
  </div>
);

const AppRoot: React.FC = () => {
  return (
    <ErrorBoundary>
      <BrowserRouter>
        <Shell>
          <Routes>
            <Route path="/" element={<Navigate to="/feed" replace/>} />
            <Route path="/feed" element={<FeedScreen />} />
            <Route path="/map" element={<MapScreen />} />
            <Route path="/catch/add" element={<AddCatchPage />} />
            <Route path="/place/add" element={<AddPlacePage />} />
            <Route path="/alerts" element={<NotificationsPage />} />
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/weather" element={<WeatherPage />} />
            <Route path="/catch/:id" element={<CatchDetailPage />} />
            <Route path="/place/:id" element={<PlaceDetailPage />} />
            <Route path="*" element={<div style={{padding:16}}>404</div>} />
          </Routes>
        </Shell>
      </BrowserRouter>
    </ErrorBoundary>
  );
};

export default AppRoot;
TSX

############################################
# 4) Безопасный main.tsx (монтирование)
############################################
cat > "$SRC/main.tsx" <<'TSX'
import React from 'react';
import { createRoot } from 'react-dom/client';
import AppRoot from './AppRoot';

const el = document.getElementById('root');
if (!el) {
  const created = document.createElement('div');
  created.id = 'root';
  document.body.appendChild(created);
}

function boot() {
  try {
    const root = createRoot(document.getElementById('root') as HTMLElement);
    root.render(<AppRoot />);
    console.log('[boot] App mounted');
    (window as any).__FTP_BOOT_OK__ = true;
  } catch (e) {
    console.error('[boot] failed', e);
    (window as any).__FTP_BOOT_ERR__ = e;
    const pre = document.createElement('pre');
    pre.style.cssText = 'padding:16px;color:#fff;background:#300;border-radius:8px';
    pre.textContent = 'Boot error: ' + String((e as any)?.message || e);
    document.body.appendChild(pre);
  }
}

window.addEventListener('error', (e) => {
  console.error('[window.error]', e.message);
});
window.addEventListener('unhandledrejection', (e:any) => {
  console.error('[unhandledrejection]', e?.reason);
});

boot();
TSX

############################################
# 5) index.html: гарантируем #root и базовые стили
############################################
INDEX="$FRONTEND_DIR/index.html"
if [ -f "$INDEX" ]; then
  # вставим #root, если его нет
  if ! grep -q '<div id="root"></div>' "$INDEX"; then
    # вставим перед </body>
    TMP="$(mktemp)"
    awk 'BEGIN{added=0}
         /<\/body>/ && !added { print "  <div id=\"root\"></div>"; added=1 }
         { print }' "$INDEX" > "$TMP" && mv "$TMP" "$INDEX"
    echo "→ inserted <div id=\"root\"></div> into index.html"
  fi
else
  # создадим минимальный index.html
  mkdir -p "$FRONTEND_DIR"
  cat > "$INDEX" <<'HTML'
<!doctype html>
<html lang="ru">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>FishTrackPro</title>
  </head>
  <body style="margin:0;background:#0b0e14;color:#e6e6e6;font-family:system-ui,-apple-system,Segoe UI,Roboto;">
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
    <noscript>Для работы приложения включите JavaScript</noscript>
  </body>
</html>
HTML
fi

echo "→ Done. Try building:"
( cd "$FRONTEND_DIR" && npm run build || true )

echo "💡 Если экран снова пустой: откройте DevTools → Console. С ErrorBoundary всё теперь логируется, а падения не скрываются."