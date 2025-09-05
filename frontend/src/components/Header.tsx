import React from "react";
import { Link } from "react-router-dom";
import Icon from "./Icon";
import { CONFIG } from "../config";

export default function Header({ points=0 }:{ points?:number }) {
  return (
    <header className="app-header">
      <div className="left">
        <Link to="/map" className="logo">
          <Icon name="logo" size={26}/>
          <span>FishTrack Pro</span>
        </Link>
      </div>
      <nav className="center">
        <Link to={CONFIG.nav.topLinks.weather} className="hdr-link"><Icon name="weather" size={22}/>Погода</Link>
        <Link to={CONFIG.nav.topLinks.map} className="hdr-link">Карта</Link>
        <Link to={CONFIG.nav.topLinks.feed} className="hdr-link">Лента</Link>
      </nav>
      <div className="right">
        <Link to={CONFIG.nav.topLinks.notifications} className="icon-btn" aria-label="Уведомления">
          <Icon name="notifications" size={24}/>
        </Link>
        <Link to={CONFIG.nav.topLinks.profile} className="avatar-btn">
          <img src={CONFIG.images.avatarDefault} alt="me" />
        </Link>
        <div className="points" title="Бонусы">
          <Icon name="rating" size={18}/> <b>{points}</b>
        </div>
      </div>
    </header>
  );
}
