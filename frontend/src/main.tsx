import React from 'react';
import { createRoot } from 'react-dom/client';
import './styles/app.css';
import AppRoot from './AppRoot';

const el = document.getElementById('root');
if (!el) {
  throw new Error('#root not found');
}
const root = createRoot(el);
console.log('[boot] App mounted');
root.render(<AppRoot />);
