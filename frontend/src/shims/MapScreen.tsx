import * as M from '../pages/MapScreen';
import React from 'react';
const pick = (mod: any): any =>
  mod?.default ??
  mod?.MapScreen ??
  Object.values(mod || {}).find((v:any)=> typeof v==='function' || (v && typeof v==='object' && 'props' in v)) ??
  (() => <div style={{padding:16}}>⚠️ Не найден экспорт для <b>MapScreen</b> из <code>../pages/MapScreen</code></div>);
const C: any = pick(M);
export default C;
