import React from 'react';
import { Link } from 'react-router-dom';

type Point = { id?: number|string; lat:number; lng:number; title?:string; photos?:string[]; kind?: 'place'|'catch' };
const PointPinCard: React.FC<{p:Point}> = ({p}) => {
  const img = p.photos?.[0];
  const link = p.kind === 'catch' ? `/catch/${p.id}` : `/place/${p.id}`;
  return (
    <div className="glass card" style={{display:'flex', gap:10}}>
      {img && <img src={img} alt="" style={{width:72, height:72, objectFit:'cover', borderRadius:8}} />}
      <div style={{flex:1}}>
        <div style={{fontWeight:600}}>{p.title || 'Точка'}</div>
        <div className="muted" style={{fontSize:12}}>
          {p.lat.toFixed(4)}, {p.lng.toFixed(4)}
        </div>
        {p.id && <Link to={link} className="btn" style={{marginTop:8}}>Открыть</Link>}
      </div>
    </div>
  );
};
export default PointPinCard;
