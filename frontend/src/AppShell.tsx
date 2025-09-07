import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import ToastHost from './components/Toast';
import AuthLoginPage from './pages/AuthLoginPage';
import AuthRegisterPage from './pages/AuthRegisterPage';
const AppShell: React.FC = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<AuthLoginPage/>} />
        <Route path="/register" element={<AuthRegisterPage/>} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
      <ToastHost/>
    </BrowserRouter>
  );
};
export default AppShell;
