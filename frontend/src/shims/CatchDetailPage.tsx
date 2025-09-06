import * as M from '../pages/CatchDetailPage';
import React from 'react';
const pick = (mod: any): any =>
  mod?.default ??
  mod?.CatchDetailPage ??
  Object.values(mod || {}).find((v:any)=> typeof v==='function' || (v && typeof v==='object' && 'props' in v)) ??
  (() => <div style={{padding:16}}>⚠️ Не найден экспорт для <b>CatchDetailPage</b> из <code>../pages/CatchDetailPage</code></div>);
const C: any = pick(M);
export default C;
