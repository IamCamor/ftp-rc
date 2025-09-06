import * as M from '../pages/ProfilePage';
import React from 'react';
const pick = (mod: any): any =>
  mod?.default ??
  mod?.ProfilePage ??
  Object.values(mod || {}).find((v:any)=> typeof v==='function' || (v && typeof v==='object' && 'props' in v)) ??
  (() => <div style={{padding:16}}>⚠️ Не найден экспорт для <b>ProfilePage</b> из <code>../pages/ProfilePage</code></div>);
const C: any = pick(M);
export default C;
