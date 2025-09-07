import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import ToastHost from './components/Toast';
import MapScreen from './pages/MapScreen';
const AppShell: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/map" element={<MapScreen/>} />
        <Route path="*" element={<Navigate to="/map" replace />} />
      </Routes>
      <ToastHost/>
    </BrowserRouter>
  );
};
export default AppShell;
