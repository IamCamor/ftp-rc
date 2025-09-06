import * as M from '../pages/NotificationsPage';
import React from 'react';
const pick = (mod: any): any =>
  mod?.default ??
  mod?.NotificationsPage ??
  Object.values(mod || {}).find((v:any)=> typeof v==='function' || (v && typeof v==='object' && 'props' in v)) ??
  (() => <div style={{padding:16}}>⚠️ Не найден экспорт для <b>NotificationsPage</b> из <code>../pages/NotificationsPage</code></div>);
const C: any = pick(M);
export default C;
