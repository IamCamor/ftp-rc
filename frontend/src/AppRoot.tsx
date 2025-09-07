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
