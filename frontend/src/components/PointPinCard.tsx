import React from 'react';
import { Link } from 'react-router-dom';

type Props = {
  id: string|number;
  type?: 'place'|'catch';
  title?: string;
  photos?: string[];
};

const PointPinCard: React.FC<Props> = ({ id, type='place', title='Точка', photos=[] }) => {
  const href = type === 'catch' ? `/catch/${id}` : `/place/${id}`;
  const img = photos[0];
  return (
    <div className="glass card" style={{minWidth:220}}>
      {img && <img src={img} alt={title} style={{width:'100%',height:140,objectFit:'cover',borderRadius:12,marginBottom:8}}/>}
      <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',gap:8}}>
        <div>
          <div style={{fontWeight:600}}>{title}</div>
          <div className="subtle">{type === 'catch' ? 'Улов' : 'Место'}</div>
        </div>
        <Link to={href} className="btn">Открыть</Link>
      </div>
    </div>
  );
};
export default PointPinCard;
