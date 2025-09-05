import React from 'react';
import Icon from './Icon';
import Avatar from './Avatar';
import { CONFIG } from '../config';

export default function Header({bonuses=0}:{bonuses?:number}){
  const go=(p:string)=>window.navigate?.(p);
  return (
    <div className="header glass">
      <div className="row">
        <a
          onClick={()=>go('/map')}
          style={{cursor:'pointer',display:'flex',alignItems:'center',gap:8}}
        >
          <img
            src={CONFIG.IMAGES.logo}
            alt="logo"
            width={28}
            height={28}
            style={{borderRadius:6}}
          />
          <b>FishTrack</b>
        </a>
        <div className="right">
          <a
            className="badge"
            onClick={()=>go('/weather')}
            style={{cursor:'pointer'}}
            title="Погода"
          >
            <Icon name="weather" />
            <span>Погода</span>
          </a>
          <a
            onClick={()=>go('/alerts')}
            title="Уведомления"
            style={{cursor:'pointer'}}
          >
            <Icon name="alerts"/>
          </a>
          <a
            onClick={()=>go('/profile')}
            className="row"
            style={{gap:8,cursor:'pointer'}}
            title="Профиль"
          >
            <Avatar src={null} />
            <span className="badge">{bonuses} бонусов</span>
          </a>
        </div>
      </div>
    </div>
  );
}
