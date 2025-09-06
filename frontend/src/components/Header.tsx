import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { config } from '../config';

type HeaderProps = {
  title?: string;
};

export function Header({ title }: HeaderProps) {
  const loc = useLocation();
  // Дефолтные иконки возьмём из конфига либо подставим текст
  const icons = config?.icons || {};
  const Logo = () => <img src={config?.assets?.logo ?? ''} alt="logo" style={{height:28, width:'auto'}} onError={(e:any)=>{e.currentTarget.style.display='none'}} />;

  return (
    <header
      style={{
        position:'sticky', top:0, zIndex:50,
        display:'flex', alignItems:'center', gap:12,
        padding:'10px 12px',
        background:'rgba(16,18,26,.65)', backdropFilter:'blur(10px)',
        borderBottom:'1px solid rgba(255,255,255,.08)'
      }}
    >
      <Link to="/feed" style={{display:'inline-flex', alignItems:'center', gap:8, textDecoration:'none', color:'#fff'}}>
        <Logo />
        <span style={{fontWeight:700, letterSpacing:.2}}>FishTrackPro</span>
      </Link>

      <div style={{flex:1}} />

      {/* Погода */}
      <Link to="/weather" title="Погода" style={{textDecoration:'none', color:'#fff'}}>
        <span className="material-symbols-rounded" style={{fontSize:24, verticalAlign:'middle'}}>
          {icons.weather ?? 'cloud'}
        </span>
      </Link>

      {/* Уведомления */}
      <Link to="/alerts" title="Уведомления" style={{textDecoration:'none', color:'#fff', marginLeft:10}}>
        <span className="material-symbols-rounded" style={{fontSize:24}}>
          {icons.notifications ?? 'notifications'}
        </span>
      </Link>

      {/* Бонусы */}
      <Link to="/profile" title="Бонусы" style={{textDecoration:'none', color:'#fff', marginLeft:10, display:'inline-flex', alignItems:'center', gap:6}}>
        <span className="material-symbols-rounded" style={{fontSize:22}}>
          {icons.bonus ?? 'military_tech'}
        </span>
        <span style={{fontWeight:600}}>{config?.user?.bonuses ?? 0}</span>
      </Link>

      {/* Аватар */}
      <Link to="/profile" title="Профиль" style={{marginLeft:10, display:'inline-flex', alignItems:'center'}}>
        <img
          src={config?.assets?.avatarDefault ?? ''}
          onError={(e:any)=>{ e.currentTarget.src=''; e.currentTarget.style.display='none'; }}
          alt="avatar" style={{width:28, height:28, borderRadius:999, objectFit:'cover', border:'1px solid rgba(255,255,255,.15)'}}
        />
      </Link>
    </header>
  );
}

export default Header;
