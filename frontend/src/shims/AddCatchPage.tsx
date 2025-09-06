import * as M from '../pages/AddCatchPage';
import React from 'react';
const pick = (mod: any): any =>
  mod?.default ??
  mod?.AddCatchPage ??
  Object.values(mod || {}).find((v:any)=> typeof v==='function' || (v && typeof v==='object' && 'props' in v)) ??
  (() => <div style={{padding:16}}>⚠️ Не найден экспорт для <b>AddCatchPage</b> из <code>../pages/AddCatchPage</code></div>);
const C: any = pick(M);
export default C;
