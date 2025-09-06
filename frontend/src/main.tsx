import React from 'react';
import { createRoot } from 'react-dom/client';
import AppRoot from './AppRoot';

const el = document.getElementById('root');
if (!el) {
  const created = document.createElement('div');
  created.id = 'root';
  document.body.appendChild(created);
}

function boot() {
  try {
    const root = createRoot(document.getElementById('root') as HTMLElement);
    root.render(<AppRoot />);
    console.log('[boot] App mounted');
    (window as any).__FTP_BOOT_OK__ = true;
  } catch (e) {
    console.error('[boot] failed', e);
    (window as any).__FTP_BOOT_ERR__ = e;
    const pre = document.createElement('pre');
    pre.style.cssText = 'padding:16px;color:#fff;background:#300;border-radius:8px';
    pre.textContent = 'Boot error: ' + String((e as any)?.message || e);
    document.body.appendChild(pre);
  }
}

window.addEventListener('error', (e) => {
  console.error('[window.error]', e.message);
});
window.addEventListener('unhandledrejection', (e:any) => {
  console.error('[unhandledrejection]', e?.reason);
});

boot();
