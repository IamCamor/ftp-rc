import * as M from '../pages/PlaceDetailPage';
import React from 'react';
const pick = (mod: any): any =>
  mod?.default ??
  mod?.PlaceDetailPage ??
  Object.values(mod || {}).find((v:any)=> typeof v==='function' || (v && typeof v==='object' && 'props' in v)) ??
  (() => <div style={{padding:16}}>⚠️ Не найден экспорт для <b>PlaceDetailPage</b> из <code>../pages/PlaceDetailPage</code></div>);
const C: any = pick(M);
export default C;
