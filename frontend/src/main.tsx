import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './AppRoot';
import './styles/app.css';

// Подключаем Material Symbols (аксисы — по алфавиту: FILL, GRAD, opsz, wght)
const fonts = document.createElement('link');
fonts.rel = 'stylesheet';
fonts.href = 'https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:FILL@0..1,GRAD@-25..200,opsz@20..48,wght@100..700';
document.head.appendChild(fonts);

const el = document.getElementById('root');
if (el) {
  const root = createRoot(el);
  root.render(<App />);
  console.log('[boot] App mounted');
}
