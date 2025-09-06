import React from 'react';
import { Link, useLocation } from 'react-router-dom';

const Tab:React.FC<{to:string; icon:string; title:string}> = ({to, icon, title}) => {
  const loc = useLocation();
  const active = loc.pathname === to || (to !== '/' && loc.pathname.startsWith(to));
  return (
    <Link className="btn" to={to} title={title} style={{opacity: active ? 1 : 0.65}}>
      <span className="material-symbols-rounded">{icon}</span>
      <span style={{marginLeft:6}}>{title}</span>
    </Link>
  );
};

const BottomNav: React.FC = () => {
  return (
    <div className="bottom-nav glass">
      <Tab to="/feed" icon="home" title="Лента" />
      <Tab to="/map" icon="map" title="Карта" />
      <Tab to="/add/catch" icon="add_circle" title="Улов" />
      <Tab to="/add/place" icon="add_location_alt" title="Место" />
    </div>
  );
};
export default BottomNav;
