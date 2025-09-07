import React from 'react';

type IconProps = {
  name: string;       // имя из Material Symbols
  className?: string;
  title?: string;
  size?: number;      // px
  fill?: 0|1;
  weight?: 100|200|300|400|500|600|700;
};

const Icon: React.FC<IconProps> = ({ name, className, title, size = 22, fill = 0, weight = 400 }) => {
  const style: React.CSSProperties = {
    fontVariationSettings: `"FILL" ${fill}, "wght" ${weight}, "GRAD" 0, "opsz" 24`,
    fontSize: size,
  };
  return (
    <span className={`material-symbols-rounded ${className||''}`} style={style} aria-label={title||name}>
      {name}
    </span>
  );
};

export default Icon;
