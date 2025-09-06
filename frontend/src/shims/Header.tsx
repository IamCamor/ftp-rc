import * as M from '../components/Header';
import React from 'react';
const pick = (mod: any): any =>
  mod?.default ??
  mod?.Header ??
  Object.values(mod || {}).find((v:any)=> typeof v==='function' || (v && typeof v==='object' && 'props' in v)) ??
  (() => <div style={{padding:16}}>⚠️ Не найден экспорт для <b>Header</b> из <code>../components/Header</code></div>);
const C: any = pick(M);
export default C;
