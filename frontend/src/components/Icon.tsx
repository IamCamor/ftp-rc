import React from 'react';

type Props = { name: string; size?: number; fill?: 0|1; weight?: number; grad?: number; className?: string; style?: React.CSSProperties };

export default function Icon({ name, size=24, fill=0, weight=400, grad=0, className='', style }: Props) {
  const styles: React.CSSProperties = {
    fontVariationSettings: `'opsz' ${size}, 'wght' ${weight}, 'FILL' ${fill}, 'GRAD' ${grad}`,
    fontSize: size,
    ...style,
  };
  return <span className={`material-symbols-rounded ${className}`} style={styles} aria-hidden="true">{name}</span>;
}
