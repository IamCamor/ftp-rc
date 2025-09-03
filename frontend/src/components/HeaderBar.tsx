import React from 'react';
import { ASSETS } from '../config/assets';
import Icon from './Icon';

type Props = {
  bonuses?: number;
  onLogoClick?: ()=>void;
  onProfileClick?: ()=>void;
  onWeatherClick?: ()=>void;
  onNotifClick?: ()=>void;
};

export default function HeaderBar({bonuses=0,onLogoClick,onProfileClick,onWeatherClick,onNotifClick}: Props){
  return (
    <div className="fixed top-0 left-0 right-0 z-40 px-3 py-2">
      <div className="backdrop-blur-md bg-white/60 border border-white/40 shadow-sm rounded-2xl flex items-center justify-between px-3 py-2">
        <div className="flex items-center gap-2">
          <img src={ASSETS.logoUrl} alt="logo" className="w-7 h-7" onClick={onLogoClick}/>
          <button onClick={onWeatherClick} className="flex items-center gap-1 text-sm px-2 py-1 rounded-xl border border-white/40 backdrop-blur bg-white/40">
            <Icon name="weather" className="w-4 h-4"/><span>Погода</span>
          </button>
        </div>
        <div className="flex items-center gap-3">
          <div className="text-xs px-2 py-1 rounded-xl bg-white/50 border border-white/40">+{bonuses}</div>
          <button onClick={onNotifClick} className="p-1 rounded-full hover:bg-white/50"><Icon name="bell" className="w-6 h-6"/></button>
          <button onClick={onProfileClick} className="flex items-center gap-2">
            <img src={ASSETS.avatarPlaceholder} alt="me" className="w-8 h-8 rounded-full object-cover"/>
          </button>
        </div>
      </div>
    </div>
  );
}
