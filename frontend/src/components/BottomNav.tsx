import React from 'react';
import { NavLink } from 'react-router-dom';
import Icon from './Icon';
import config from '../config';

const cls = (isActive:boolean) =>
  `icon-btn ${isActive ? 'glass' : ''}`;

const BottomNav: React.FC = () => {
  return (
    <nav className="bottom-nav glass" role="navigation" aria-label="bottom navigation">
      <NavLink to="/" className={({isActive}) => cls(isActive)} aria-label="feed">
        <Icon name={config.icons.feed || 'dynamic_feed'} />
      </NavLink>

      <NavLink to="/map" className={({isActive}) => cls(isActive)} aria-label="map">
        <Icon name={config.icons.map || 'map'} />
      </NavLink>

      <NavLink to="/add/catch" className={({isActive}) => cls(isActive)} aria-label="add catch">
        <Icon name={config.icons.add || 'add'} />
      </NavLink>

      <NavLink to="/alerts" className={({isActive}) => cls(isActive)} aria-label="alerts">
        <Icon name={config.icons.bell || 'notifications'} />
      </NavLink>

      <NavLink to="/profile" className={({isActive}) => cls(isActive)} aria-label="profile">
        <Icon name={config.icons.profile || 'account_circle'} />
      </NavLink>
    </nav>
  );
};

export default BottomNav;
