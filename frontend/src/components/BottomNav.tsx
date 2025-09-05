import React from "react";
import { NavLink } from "react-router-dom";
import Icon from "./Icon";
import { CONFIG } from "../config";

function BottomNav() {
  const nav = [
    { to: "/", icon: CONFIG.icons.feed, label: "Лента", end: true },
    { to: "/map", icon: CONFIG.icons.map, label: "Карта" },
    { to: "/add-catch", icon: CONFIG.icons.add, label: "Добавить" },
    { to: "/alerts", icon: CONFIG.icons.alerts, label: "Уведомл." },
    { to: "/profile", icon: CONFIG.icons.profile, label: "Профиль" },
  ];
  return (
    <nav className="bottom-nav">
      {nav.map((i) => (
        <NavLink
          key={i.to}
          to={i.to}
          end={i.end as any}
          className={({ isActive }) => "bn-item" + (isActive ? " active" : "")}
        >
          <Icon name={i.icon} />
          <span>{i.label}</span>
        </NavLink>
      ))}
    </nav>
  );
}
export default BottomNav;
