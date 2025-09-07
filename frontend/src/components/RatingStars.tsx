import React, { useState } from 'react';
import Icon from './Icon';

const clamp = (n:number, a=1, b=5)=> Math.max(a, Math.min(b, n));

const RatingStars: React.FC<{
  value?: number;
  onChange?: (v:number)=>void;
  size?: number;
}> = ({value=0, onChange, size=22}) => {
  const [hover, setHover] = useState<number|null>(null);
  const v = clamp(Math.round(hover ?? value), 0, 5);
  return (
    <div className="row" role="radiogroup" aria-label="Оценка">
      {[1,2,3,4,5].map(i=>(
        <button
          key={i}
          type="button"
          className="btn"
          style={{padding:'6px 8px'}}
          aria-checked={v>=i}
          role="radio"
          onMouseEnter={()=>setHover(i)}
          onMouseLeave={()=>setHover(null)}
          onClick={()=> onChange?.(i)}
          title={`${i} из 5`}
        >
          <Icon name={v>=i? 'star':'star_rate'} size={size} />
        </button>
      ))}
    </div>
  );
};
export default RatingStars;
