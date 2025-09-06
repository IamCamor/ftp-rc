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
