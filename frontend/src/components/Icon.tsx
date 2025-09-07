import React from 'react';

type Props = {
  name: string;
  size?: number | string; // 24 по умолчанию
  className?: string;
  title?: string;
};
const Icon: React.FC<Props> = ({ name, size=24, className='', title }) => {
  const s = typeof size === 'number' ? `${size}px` : size;
  return (
    <span className={`material-symbols-rounded ${className}`} style={{fontSize:s, lineHeight:1}} aria-hidden title={title}>
      {name}
    </span>
  );
};

export default Icon;
