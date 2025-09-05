import React from 'react';
import Icon from './Icon';

const items = [
  {key:'map',   title:'Карта',  icon:'map'},
  {key:'feed',  title:'Лента',  icon:'feed'},
  {key:'alerts',title:'Оповещ.',icon:'alerts'},
  {key:'profile',title:'Профиль',icon:'profile'},
] as const;

export default function BottomNav({active}:{active:string}){
  const go=(p:string)=>window.navigate?.(p);
  return (
    <div className="tabs">
      <div className="glass inner">
        {items.map(it=>{
          const href = '/'+it.key;
          const isActive = active===href || (active==='/' && it.key==='map');
          return (
            <a key={it.key} className={`tab ${isActive?'active':''}`} onClick={()=>go(href)} style={{cursor:'pointer'}}>
              <Icon name={it.icon}/>
              <span>{it.title}</span>
            </a>
          );
        })}
      </div>
    </div>
  );
}
