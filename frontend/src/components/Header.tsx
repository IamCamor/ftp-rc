import React from 'react';
import Icon from './Icon';
import { ICONS } from '../config';

export default function Header() {
  return (
    <div className="header glass">
      <div className="brand"><a href="/feed">FishTrack<span style={{opacity:.6}}>Pro</span></a></div>
      <a href="/weather" title="Погода" aria-label="Погода"><Icon name={ICONS.header.weather} /></a>
      <a href="/alerts" title="Уведомления" aria-label="Уведомления"><Icon name={ICONS.header.bell} /></a>
      <a href="/profile" title="Профиль" aria-label="Профиль"><Icon name={ICONS.header.profile} /></a>
    </div>
  );
}
