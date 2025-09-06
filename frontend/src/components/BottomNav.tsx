import React from 'react';
import Icon from './Icon';
import { ICONS } from '../config';

const items = [
  { href:'/feed', label:'Лента', icon: ICONS.bottom.feed },
  { href:'/map', label:'Карта', icon: ICONS.bottom.map },
  { href:'/add-catch', label:'Улов', icon: ICONS.bottom.addCatch },
  { href:'/add-place', label:'Место', icon: ICONS.bottom.addPlace },
  { href:'/alerts', label:'Алерты', icon: ICONS.bottom.alerts },
];

export default function BottomNav(){
  const path = typeof window !== 'undefined' ? window.location.pathname : '';
  return (
    <nav className="bottom-nav glass">
      {items.map(it=>{
        const active = path===it.href;
        return (
          <a key={it.href} href={it.href} className={active?'active':''} aria-label={it.label}>
            <div><Icon name={it.icon} /></div>
            <div style={{fontSize:10, marginTop:2}}>{it.label}</div>
          </a>
        );
      })}
    </nav>
  );
}
