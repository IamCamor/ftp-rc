import React from 'react';
import { Point } from '../types';
import Icon from './Icon';

export default function PointPinCard({point,onOpen}:{point:Point; onOpen: (id:number|string)=>void}){
  const img = point.photo?.url || point.photos?.[0]?.url || '';
  return (
    <div className="glass-card card" style={{display:'grid',gridTemplateColumns:'88px 1fr',gap:12}}>
      {img ? <img src={img} alt="" style={{width:88,height:88,borderRadius:12,objectFit:'cover',border:'1px solid var(--stroke)'}}/> :
        <div style={{width:88,height:88,borderRadius:12,border:'1px dashed var(--stroke)',display:'grid',placeItems:'center',color:'var(--muted)'}}><Icon name="map"/></div>
      }
      <div>
        <div style={{fontWeight:600,marginBottom:6}}>{point.title||'Точка'}</div>
        <div className="small" style={{marginBottom:10}}>Тип: {point.type}</div>
        <button className="button ghost" onClick={()=>onOpen(point.id)}>Открыть</button>
      </div>
    </div>
  );
}
