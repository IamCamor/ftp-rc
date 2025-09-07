import React from 'react';
import AuthLoginPage from './pages/AuthLoginPage';
import AuthRegisterPage from './pages/AuthRegisterPage';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import ToastHost from './components/Toast';
import MapScreen from './pages/MapScreen';
const AppShell: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<AuthLoginPage/>} />
        <Route path="/register" element={<AuthRegisterPage/>} />
        <Route path="/map" element={<MapScreen/>} />
        <Route path="*" element={<Navigate to="/map" replace />} />
      </Routes>
      <ToastHost/>
    </BrowserRouter>
  );
};
export default AppShell;
