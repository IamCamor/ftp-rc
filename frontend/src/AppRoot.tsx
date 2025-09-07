import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import FeedScreen from './pages/FeedScreen';
import MapScreen from './pages/MapScreen';
import CatchDetailPage from './pages/CatchDetailPage';
import AddCatchPage from './pages/AddCatchPage';
import AddPlacePage from './pages/AddPlacePage';
import NotificationsPage from './pages/NotificationsPage';
import ProfilePage from './pages/ProfilePage';
import WeatherPage from './pages/WeatherPage';
import PlaceDetailPage from './pages/PlaceDetailPage';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';

export default function AppRoot(){
  return (
    <Routes>
      <Route path="/" element={<FeedScreen />} />
      <Route path="/map" element={<MapScreen />} />
      <Route path="/catch/:id" element={<CatchDetailPage />} />
      <Route path="/place/:id" element={<PlaceDetailPage />} />
      <Route path="/add/catch" element={<AddCatchPage />} />
      <Route path="/add/place" element={<AddPlacePage />} />
      <Route path="/alerts" element={<NotificationsPage />} />
      <Route path="/profile" element={<ProfilePage />} />
      <Route path="/weather" element={<WeatherPage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
