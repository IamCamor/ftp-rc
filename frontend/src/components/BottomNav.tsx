import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';
import Icon from './Icon';

const BottomNav: React.FC = () => {
  const { pathname } = useLocation();
  const is = (p: string) => pathname.startsWith(p);
  const Item: React.FC<{to:string; icon:string; label:string}> = ({to, icon, label}) => (
    <Link to={to} className={`bottom-link glass ${is(to)?'active':''}`}>
      <Icon name={icon} />
      <small>{label}</small>
    </Link>
  );
  return (
    <nav className="bottom-nav glass">
      <Item to="/feed" icon={config.icons.home} label="Лента" />
      <Item to="/map" icon={config.icons.map} label="Карта" />
      <Item to="/add/place" icon={config.icons.add} label="Место" />
      <Item to="/alerts" icon={config.icons.alerts} label="Оповещения" />
      <Item to="/profile" icon={config.icons.profile} label="Профиль" />
    </nav>
  );
};

export default BottomNav;
