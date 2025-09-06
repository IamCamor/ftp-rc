import * as M from '../pages/AddPlacePage';
import React from 'react';
const pick = (mod: any): any =>
  mod?.default ??
  mod?.AddPlacePage ??
  Object.values(mod || {}).find((v:any)=> typeof v==='function' || (v && typeof v==='object' && 'props' in v)) ??
  (() => <div style={{padding:16}}>⚠️ Не найден экспорт для <b>AddPlacePage</b> из <code>../pages/AddPlacePage</code></div>);
const C: any = pick(M);
export default C;
