import React from "react";
import { CONFIG } from "../config";

export default function Avatar({ src, size = 32 }: { src?: string; size?: number }) {
  return (
    <img
      src={src || CONFIG.assets.avatar}
      alt="avatar"
      style={{ width: size, height: size }}
      className="avatar"
    />
  );
}
