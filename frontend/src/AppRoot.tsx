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
