import React from 'react';
import config from '../config';

const Avatar: React.FC<{src?:string; size?:number; alt?:string}> = ({src, size=40, alt='avatar'}) => {
  const fallback = config?.images?.defaultAvatar || '/assets/default-avatar.png';
  return (
    <img
      src={src || fallback}
      alt={alt}
      style={{ width:size, height:size, borderRadius:'50%', objectFit:'cover', border:'1px solid rgba(255,255,255,.2)'}}
    />
  );
};
export default Avatar;
