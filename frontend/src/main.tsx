import React from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import AppRoot from './AppRoot';

console.log('[boot] App mounted');
const el = document.getElementById('root')!;
createRoot(el).render(
  <BrowserRouter>
    <AppRoot />
  </BrowserRouter>
);
