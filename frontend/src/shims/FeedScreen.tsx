import * as M from '../pages/FeedScreen';
import React from 'react';
const pick = (mod: any): any =>
  mod?.default ??
  mod?.FeedScreen ??
  Object.values(mod || {}).find((v:any)=> typeof v==='function' || (v && typeof v==='object' && 'props' in v)) ??
  (() => <div style={{padding:16}}>⚠️ Не найден экспорт для <b>FeedScreen</b> из <code>../pages/FeedScreen</code></div>);
const C: any = pick(M);
export default C;
