import React from 'react';
import type { Media } from '../types';

export default function MediaGrid({items}:{items:Media[]|undefined}){
  if(!items || !items.length) return null;
  return (
    <div className="media-grid">
      {items.map((m,i)=> m.type==='video'
        ? <video key={i} src={m.url} controls playsInline/>
        : <img key={i} src={m.url} alt="" loading="lazy"/> )}
    </div>
  );
}
