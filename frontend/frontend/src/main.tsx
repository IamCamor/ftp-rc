import React from 'react';
import { createRoot } from 'react-dom/client';
import AppShell from './AppShell';
const el = document.getElementById('root')!;
createRoot(el).render(<AppShell/>);
console.log('[boot] App mounted');
