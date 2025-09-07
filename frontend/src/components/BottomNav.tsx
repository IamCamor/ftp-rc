import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import Icon from './Icon';

export default function BottomNav(){
  const loc = useLocation();
  const is = (p:string)=> loc.pathname===p || loc.pathname.startsWith(p+'/');
  return (
    <nav className="bottom-nav glass">
      <Link to="/" className={is('/')?'active':''}><Icon name="home" /><span>Лента</span></Link>
      <Link to="/map" className={is('/map')?'active':''}><Icon name="map" /><span>Карта</span></Link>
      <Link to="/add/catch" className={is('/add/catch')?'active':''}><Icon name="add_a_photo" /><span>Улов</span></Link>
      <Link to="/add/place" className={is('/add/place')?'active':''}><Icon name="add_location" /><span>Место</span></Link>
      <Link to="/profile" className={is('/profile')?'active':''}><Icon name="person" /><span>Профиль</span></Link>
    </nav>
  );
}
