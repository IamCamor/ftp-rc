import React from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { CONFIG } from "../config";
import Icon from "./Icon";

function Header() {
  const loc = useLocation();
  const navigate = useNavigate();

  return (
    <header className="app-header" style={{ backgroundImage: `url(${CONFIG.assets.background})` }}>
      <div className="left">
        <img src={CONFIG.assets.logo} alt="logo" className="logo" onClick={() => navigate("/")} />
      </div>
      <nav className="right">
        <Link to="/weather" className="header-link" title="Погода">
          <Icon name={CONFIG.icons.weather} />
          <span className="hide-sm">Погода</span>
        </Link>
        <Link to="/alerts" className="header-link" title="Уведомления">
          <Icon name={CONFIG.icons.alerts} />
          <span className="badge">●</span>
        </Link>
        <Link to="/profile" className="header-link profile-link" title="Профиль">
          <img src={CONFIG.assets.avatar} alt="avatar" className="avatar" />
        </Link>
      </nav>
    </header>
  );
}

export default Header;
