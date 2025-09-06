import React from 'react';

/**
 * Универсальная иконка на Material Symbols Rounded.
 * Требует <link> на шрифт в index.html:
 *   https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@24,400,0,0
 */
export type IconProps = {
  name: string;      // название иконки, например: "map", "notifications"
  size?: number;     // px
  title?: string;
  className?: string;
  /**
   * оси шрифта — можно не трогать: дефолты ок
   */
  fill?: 0 | 1;
  weight?: 100 | 200 | 300 | 400 | 500 | 600 | 700;
  grade?: -25 | 0 | 200;
  opsz?: 20 | 24 | 40 | 48;
  style?: React.CSSProperties;
};

export const Icon: React.FC<IconProps> = ({
  name,
  size = 24,
  title,
  className = '',
  fill = 0,
  weight = 400,
  grade = 0,
  opsz = 24,
  style = {},
}) => {
  const fontVariationSettings = `'FILL' ${fill}, 'wght' ${weight}, 'GRAD' ${grade}, 'opsz' ${opsz}`;
  return (
    <span
      className={`material-symbols-rounded ${className}`.trim()}
      aria-hidden={title ? undefined : true}
      title={title}
      style={{
        fontVariationSettings,
        fontSize: size,
        lineHeight: 1,
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        ...style,
      }}
    >
      {name}
    </span>
  );
};

// Именованный и дефолтный экспорт — чтобы любые импорты работали
export default Icon;
