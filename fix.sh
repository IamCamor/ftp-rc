#!/usr/bin/env bash
set -euo pipefail

# --- жёстко работаем от корня с путями frontend/src ---
FRONTEND_DIR="frontend"
SRC_DIR="$FRONTEND_DIR/src"
TARGET="$SRC_DIR/AppRoot.tsx"

if [ ! -d "$SRC_DIR" ]; then
  echo "❌ Не найден каталог $SRC_DIR. Запустите скрипт из КОРНЯ проекта."
  exit 1
fi

# Создадим layouts/AppLayout.tsx, если его нет — это стабильный универсальный layout,
# чтобы не ломать навигацию и шапку/меню при следующих правках.
LAYOUT_DIR="$SRC_DIR/layouts"
mkdir -p "$LAYOUT_DIR"

cat > "$LAYOUT_DIR/AppLayout.tsx" <<'TS'
import React from 'react';
import Header from '../components/Header';
import BottomNav from '../components/BottomNav';

const AppLayout: React.FC<React.PropsWithChildren> = ({ children }) => {
  return (
    <div className="app-shell">
      <Header />
      <main className="app-content">{children}</main>
      <BottomNav />
    </div>
  );
};

export default AppLayout;
TS

# Обновляем AppRoot.tsx с корректными lazy-импортами БЕЗ @vite-ignore
cat > "$TARGET" <<'TS'
import React, { Suspense, lazy } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import AppLayout from './layouts/AppLayout';

// Хелпер: выбирает default/именованный экспорт, сохраняя статический import() для Vite
function pick<T = any>(m: any, named?: string) {
  return (m?.default ?? (named ? m[named] : undefined) ?? Object.values(m).find((v:any)=> typeof v === 'function')) as React.ComponentType<any> || (()=>null);
}

// Важно: строки путей статичны — Vite сделает чанки и подставит правильные URL
const FeedScreen        = lazy(() => import('./pages/FeedScreen').then(m => ({ default: pick(m, 'FeedScreen') })));
const MapScreen         = lazy(() => import('./pages/MapScreen').then(m => ({ default: pick(m, 'MapScreen') })));
const AddCatchPage      = lazy(() => import('./pages/AddCatchPage').then(m => ({ default: pick(m, 'AddCatchPage') })));
const AddPlacePage      = lazy(() => import('./pages/AddPlacePage').then(m => ({ default: pick(m, 'AddPlacePage') })));
const NotificationsPage = lazy(() => import('./pages/NotificationsPage').then(m => ({ default: pick(m, 'NotificationsPage') })));
const ProfilePage       = lazy(() => import('./pages/ProfilePage').then(m => ({ default: pick(m, 'ProfilePage') })));
const WeatherPage       = lazy(() => import('./pages/WeatherPage').then(m => ({ default: pick(m, 'WeatherPage') })));
const CatchDetailPage   = lazy(() => import('./pages/CatchDetailPage').then(m => ({ default: pick(m, 'CatchDetailPage') })));
const PlaceDetailPage   = lazy(() => import('./pages/PlaceDetailPage').then(m => ({ default: pick(m, 'PlaceDetailPage') })));

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

echo "✅ Обновлено: $TARGET"
echo "✅ Обновлено: $LAYOUT_DIR/AppLayout.tsx"

cat <<'NEXT'
Дальше:
1) cd frontend
2) npm run build
3) npm run preview  (или деплой на сервер)

Если на проде всё ещё 404 по чанкам — проверьте конфиг веб-сервера:
- статику из dist/assets/* отдавать напрямую (не переписывать на index.html)
- остальные пути SPA маршрутизировать на index.html
NEXT