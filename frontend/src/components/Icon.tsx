import React from "react";
import { ICONS } from "../config/ui";

type Props = {
  name: keyof typeof ICONS | string;
  className?: string;
  size?: number;
  weight?: number;
  grade?: number;
  fill?: 0|1;
  title?: string;
};

export default function Icon({ name, className="", size=24, weight=400, grade=0, fill=0, title }: Props){
  const glyph = (ICONS as any)[name] ?? name;
  return (
    <span
      className={`material-symbols-rounded ${className}`}
      style={{ fontSize: size, fontVariationSettings: `'FILL' ${fill}, 'wght' ${weight}, 'GRAD' ${grade}, 'opsz' ${Math.max(20, size)}` }}
      aria-label={title || (typeof name === "string" ? name : "")}
      title={title}
    >
      {glyph}
    </span>
  );
}
