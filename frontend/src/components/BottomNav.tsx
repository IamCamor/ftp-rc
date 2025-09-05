import React from "react";
import { Link, useLocation } from "react-router-dom";
import Icon from "./Icon";
import { CONFIG } from "../config";

export default function BottomNav() {
  const loc = useLocation();
  return (
    <nav className="bottom-nav">
      {CONFIG.nav.bottomTabs.map(tab=>{
        const active = loc.pathname.startsWith(tab.path);
        return (
          <Link key={tab.key} to={tab.path} className={"bn-item"+(active?" active":"")}>
            <Icon name={tab.icon} size={22}/>
            <span>{tab.label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
