import React from 'react';
import { Link } from 'react-router-dom';
import config from '../config';
import Icon from './Icon';

const Header: React.FC = () => {
  const logo = config?.images?.logoUrl || '/src/assets/logo.svg';
  return (
    <header className="header glass">
      <div className="left">
        <Link to="/feed" className="row" aria-label="На главную">
          <img src={logo} alt="Logo" style={{height:28}} />
        </Link>
      </div>
      <div className="right">
        <Link to="/weather" className="btn" title="Погода">
          <Icon name={config.icons.weather} /> <span className="hide-sm">Погода</span>
        </Link>
        <Link to="/add/catch" className="btn primary" title="Добавить улов">
          <Icon name={config.icons.add} /> <span className="hide-sm">Улов</span>
        </Link>
      </div>
    </header>
  );
};

export default Header;
