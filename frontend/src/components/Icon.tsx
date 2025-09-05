import React from "react";
import * as Icons from "@mui/icons-material";

// Универсальная обёртка для MUI-иконок (имена задаём в CONFIG.icons)
export default function Icon({ name, size = 24 }: { name: string; size?: number }) {
  const Cmp = (Icons as any)[name];
  if (!Cmp) return <span className="icon-missing">{name}</span>;
  return <Cmp style={{ fontSize: size }} />;
}
