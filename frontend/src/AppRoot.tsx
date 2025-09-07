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

import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import { isAuthed } from './api';

const ProtectedRoute: React.FC<{ children: React.ReactElement }> = ({ children }) => {
  if (!isAuthed()) return <Navigate to="/login" replace />;
  return children;
};

const AppRoot: React.FC = () => {
  return (
    <BrowserRouter>
      <div className="app-shell">
        <Header />
        <main className="app-main">
          <Routes>
            <Route path="/" element={<Navigate to="/feed" replace />} />
            <Route path="/feed" element={<FeedScreen />} />
            <Route path="/map" element={<MapScreen />} />
            <Route path="/catch/:id" element={<CatchDetailPage />} />
            <Route path="/place/:id" element={<PlaceDetailPage />} />
            <Route path="/weather" element={<WeatherPage />} />
            <Route path="/alerts" element={<NotificationsPage />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />

            <Route path="/add/catch" element={<ProtectedRoute><AddCatchPage /></ProtectedRoute>} />
            <Route path="/add/place" element={<ProtectedRoute><AddPlacePage /></ProtectedRoute>} />
            <Route path="/profile" element={<ProtectedRoute><ProfilePage /></ProtectedRoute>} />

            <Route path="*" element={<Navigate to="/feed" replace />} />
          </Routes>
        </main>
        <BottomNav />
      </div>
      <style>{`
        .app-shell { min-height: 100svh; display: grid; grid-template-rows: auto 1fr auto; }
        .app-main { min-height: 0; }
      `}</style>
    </BrowserRouter>
  );
};

export default AppRoot;
