import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import { ensureMaterialSymbols } from './utils/fonts';

ensureMaterialSymbols();

const el = document.getElementById('root');
if (!el) {
  const e = document.createElement('div');
  e.id = 'root';
  document.body.appendChild(e);
}

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

console.log('[boot] App mounted');

// global handler — чтобы «Failed to fetch» показывался понятно
window.addEventListener('unhandledrejection', (ev) => {
  const r = ev.reason;
  const msg = (r && (r.message || r.toString())) || 'Network error';
  if (String(msg).includes('Failed to fetch')) {
    console.warn('[network] Вероятно, сеть/CORS/backend:', msg);
  }
});
