import React from 'react';
import { NavLink } from 'react-router-dom';

const Item: React.FC<{to:string; icon:string; label:string}> = ({to, icon, label}) => (
  <NavLink to={to} className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
    <span className="icon">{icon}</span>
    <span>{label}</span>
  </NavLink>
);

const BottomNav: React.FC = () => {
  return (
    <nav className="glass footer-glass">
      <div className="bottom-bar" style={{justifyContent:'space-around'}}>
        <Item to="/feed" icon="home" label="Лента"/>
        <Item to="/map" icon="map" label="Карта"/>
        <Item to="/add/catch" icon="add_circle" label="Улов"/>
        <Item to="/alerts" icon="notifications" label="Оповещения"/>
        <Item to="/profile" icon="person" label="Профиль"/>
      </div>
    </nav>
  );
};

export default BottomNav;
export { BottomNav };
