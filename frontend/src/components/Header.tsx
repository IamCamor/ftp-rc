import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';

type HeaderProps = { bonuses?: number };

const Header: React.FC<HeaderProps> = ({ bonuses = 0 }) => {
  const { pathname } = useLocation();
  const onWeather = ['/weather'].includes(pathname);

  return (
    <header className="glass header-glass">
      <div className="header-bar">
        <div className="brand">
          <img src={config.assets.logo} alt="logo"/>
          <span className="title">FishTrack Pro</span>
        </div>
        <div className="nav-row">
          <Link to="/weather" className={`btn ${onWeather ? 'active' : ''}`} title="Погода">
            <span className="icon">cloud</span>
            <span>Погода</span>
          </Link>
          <Link to="/alerts" className="btn" title="Уведомления">
            <span className="icon">notifications</span>
          </Link>
          <Link to="/profile" className="btn" title="Профиль">
            <span className="icon">person</span>
            <span style={{marginLeft:4}}>{bonuses}</span>
          </Link>
        </div>
      </div>
    </header>
  );
};

export default Header;
export { Header };
