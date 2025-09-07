import React from 'react';

const Icon: React.FC<{name:string; size?:number; className?:string; title?:string}> = ({name, size=24, className='', title}) => (
  <span
    className={`material-symbols-rounded ${className}`}
    style={{fontSize: size, lineHeight: 1, display:'inline-flex', verticalAlign:'middle'}}
    aria-hidden={title? undefined : true}
    title={title}
  >
    {name}
  </span>
);

export default Icon;
