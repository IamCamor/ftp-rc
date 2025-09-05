import React from "react";
import * as MI from "@mui/icons-material";
import { CONFIG } from "../config";

// Универсальный компонент: <Icon name="Favorite" />
export default function Icon({ name, size=24, className="", title }:{name:string,size?:number,className?:string,title?:string}) {
  const IconComp = (MI as any)[CONFIG.icons[name] || name] || (MI as any)["HelpOutline"];
  return <IconComp fontSize="inherit" sx={{ fontSize: size }} className={className} titleAccess={title} />;
}
