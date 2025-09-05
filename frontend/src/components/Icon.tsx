import React from "react";

type Props = {
  name: string;
  size?: number;
  fill?: 0 | 1;
  weight?: 100|200|300|400|500|600|700;
  grad?: number;
  className?: string;
  title?: string;
};

export default function Icon({
  name,
  size = 24,
  fill = 0,
  weight = 400,
  grad = 0,
  className = "",
  title,
}: Props) {
  const style: React.CSSProperties = {
    fontVariationSettings: `'FILL' ${fill}, 'wght' ${weight}, 'GRAD' ${grad}, 'opsz' ${size}`,
    fontSize: size,
  };
  return (
    <span
      className={`material-symbols-rounded ${className}`}
      style={style}
      aria-hidden={title ? undefined : true}
      title={title}
    >
      {name}
    </span>
  );
}
