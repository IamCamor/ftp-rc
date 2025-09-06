import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';

const Header: React.FC = () => {
  const loc = useLocation();
  return (
    <div className="header glass">
      <div className="brand">
        <img src={config.brand.logoUrl} alt="logo"/>
        <strong>{config.brand.name}</strong>
      </div>
      <div className="nav-actions">
        <Link className="btn" to="/weather" title="Погода">
          <span className="material-symbols-rounded">sunny</span>
        </Link>
        <Link className="btn" to="/alerts" title="Уведомления">
          <span className="material-symbols-rounded">notifications</span>
        </Link>
        <Link className="btn" to="/profile" title="Профиль">
          <span className="material-symbols-rounded">account_circle</span>
        </Link>
      </div>
    </div>
  );
};
export default Header;
