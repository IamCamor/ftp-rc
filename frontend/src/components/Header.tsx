import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';
import Icon from './Icon';

type HeaderProps = {
  title?: string;
};

const Header: React.FC<HeaderProps> = ({ title }) => {
  const loc = useLocation();

  return (
    <header className="header glass" role="banner" aria-label="main header">
      <Link to="/" className="icon-btn" aria-label="home">
        <Icon name={config.icons.logo || 'waves'} size={24} />
        <strong>{config.appName}</strong>
      </Link>

      <div className="header__spacer" />

      {config.features.ui.showWeatherLinkInHeader && (
        <Link to="/weather" className="icon-btn" aria-label="weather link">
          <Icon name={config.icons.weather || 'partly_cloudy_day'} />
        </Link>
      )}

      <Link to="/alerts" className="icon-btn" aria-label="notifications link">
        <Icon name={config.icons.bell || 'notifications'} />
      </Link>

      <Link to="/profile" className="icon-btn" aria-label="profile link">
        <Icon name={config.icons.profile || 'account_circle'} />
      </Link>
    </header>
  );
};

export default Header;
