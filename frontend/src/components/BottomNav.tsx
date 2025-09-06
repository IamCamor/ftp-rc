import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { config } from '../config';

type Item = { to: string; label: string; icon: string; };

const navItems = (icons:any): Item[] => ([
  { to:'/feed',  label:'Лента',   icon: icons.feed   ?? 'dynamic_feed' },
  { to:'/map',   label:'Карта',   icon: icons.map    ?? 'map' },
  { to:'/catch/add', label:'Улов', icon: icons.addCatch ?? 'add_a_photo' },
  { to:'/place/add', label:'Место',icon: icons.addPlace ?? 'add_location_alt' },
  { to:'/profile',   label:'Профиль', icon: icons.profile ?? 'account_circle' },
]);

export function BottomNav() {
  const { pathname } = useLocation();
  const icons = config?.icons || {};

  return (
    <nav
      style={{
        position:'fixed', left:0, right:0, bottom:0, zIndex:50,
        display:'grid', gridTemplateColumns:'repeat(5, 1fr)',
        background:'rgba(16,18,26,.7)', backdropFilter:'blur(10px)',
        borderTop:'1px solid rgba(255,255,255,.08)'
      }}
    >
      {navItems(icons).map(it => {
        const active = pathname.startsWith(it.to);
        return (
          <Link
            key={it.to}
            to={it.to}
            style={{
              padding:'10px 4px',
              textDecoration:'none',
              color: active ? '#fff' : 'rgba(255,255,255,.75)',
              display:'flex', flexDirection:'column', alignItems:'center', gap:4,
              fontSize:11
            }}
          >
            <span className="material-symbols-rounded" style={{fontSize:24}}>
              {it.icon}
            </span>
            <span>{it.label}</span>
          </Link>
        );
      })}
    </nav>
  );
}

export default BottomNav;
