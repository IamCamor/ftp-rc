import * as M from '../pages/WeatherPage';
import React from 'react';
const pick = (mod: any): any =>
  mod?.default ??
  mod?.WeatherPage ??
  Object.values(mod || {}).find((v:any)=> typeof v==='function' || (v && typeof v==='object' && 'props' in v)) ??
  (() => <div style={{padding:16}}>⚠️ Не найден экспорт для <b>WeatherPage</b> из <code>../pages/WeatherPage</code></div>);
const C: any = pick(M);
export default C;
