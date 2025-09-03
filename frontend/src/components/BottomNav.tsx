import React from "react";
import { NavLink, useLocation, useNavigate } from "react-router-dom";
import Icon from "./Icon";

export default function BottomNav({ onFab }:{ onFab?: ()=>void }){
  const nav = useNavigate();
  const loc = useLocation();

  const Fab = () => (
    <div className="absolute left-0 right-0 bottom-8 flex justify-center pointer-events-none">
      <button
        className="pointer-events-auto rounded-full w-14 h-14 flex items-center justify-center shadow-lg bg-black text-white"
        onClick={()=>{
          if (loc.pathname.startsWith("/feed")) nav("/add-catch");
          else nav("/add-place");
        }}
        aria-label="Добавить"
      >
        <Icon name="plus" />
      </button>
    </div>
  );

  const Item = ({to, label, icon}:{to:string; label:string; icon:string}) => (
    <NavLink
      to={to}
      className={({isActive})=>`flex flex-col items-center flex-1 py-2 ${isActive ? "text-black" : "text-gray-500"}`}
    >
      <Icon name={icon} />
      <span className="text-[11px] mt-0.5">{label}</span>
    </NavLink>
  );

  return (
    <div className="z-bottomnav fixed bottom-0 left-0 right-0">
      <div className="mx-auto max-w-md relative">
        <Fab/>
        <div className="rounded-t-2xl backdrop-blur bg-white/70 border-t border-white/50 shadow flex">
          <Item to="/map" label="Карта" icon="map" />
          <Item to="/feed" label="Лента" icon="feed" />
          <div className="w-14" />
          <Item to="/alerts" label="Оповещения" icon="alerts" />
          <Item to="/profile" label="Профиль" icon="profile" />
        </div>
      </div>
    </div>
  );
}
