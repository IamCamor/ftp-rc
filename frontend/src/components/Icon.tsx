import React from 'react';
import { CONFIG, IconName } from '../config';

interface Props extends React.HTMLAttributes<HTMLSpanElement>{
  name: IconName | string;
  className?: string;
  fill?: 0|1;
  size?: number; // opsz
  weight?: number; // wght
  grade?: number; // GRAD
  title?: string;
}

export default function Icon({name,className,fill=0,size=24,weight=400,grade=0,...rest}:Props){
  const glyph = (CONFIG.Icons as any)[name] || name;
  const style: React.CSSProperties = {
    fontVariationSettings: `"FILL" ${fill}, "GRAD" ${grade}, "opsz" ${size}, "wght" ${weight}`
  };
  return (
    <span className={`material-symbols-rounded icon ${className||''}`} style={style} {...rest}>
      {glyph}
    </span>
  );
}
