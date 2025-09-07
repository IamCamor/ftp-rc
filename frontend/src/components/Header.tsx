import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';
import Icon from './Icon';

export default function Header(){
  const loc = useLocation();
  return (
    <header className="glass header">
      <Link to="/" className="brand">
        <img src={config.assets?.logoUrl} alt="logo" />
        <b>FishTrack Pro</b>
      </Link>
      <nav className="actions">
        <Link to="/weather" className={loc.pathname.startsWith('/weather')?'active':''}>
          <Icon name="cloud" />
          <span className="hide-sm">Погода</span>
        </Link>
        <Link to="/alerts" className={loc.pathname.startsWith('/alerts')?'active':''}>
          <Icon name="notifications" />
        </Link>
        <Link to="/profile" className={loc.pathname.startsWith('/profile')?'active':''}>
          <Icon name="account_circle" />
        </Link>
      </nav>
    </header>
  );
}
