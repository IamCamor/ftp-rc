import React from 'react';
import { CONFIG } from '../config';

export default function Avatar({src,size=32}:{src?:string|null; size?:number}){
  const url = src || CONFIG.IMAGES.avatarDefault;
  return <img src={url} alt="" width={size} height={size}
    style={{borderRadius:'50%',border:'1px solid var(--stroke)',objectFit:'cover'}}/>;
}
