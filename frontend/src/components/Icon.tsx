import React from 'react';
type Props = { name: string; className?: string; style?: React.CSSProperties; title?: string };
/** Универсальные Material Symbols (иконки задаём строкой в конфиге/коде) */
export default function Icon({ name, className, style, title }: Props){
  return <span className={`material-symbols-rounded ${className??''}`} style={style} aria-hidden title={title}>{name}</span>;
}
export { Icon };
