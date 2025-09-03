import React from "react";
import Icon from "./Icon";

type Tab = "map"|"feed"|"alerts"|"profile";

export default function BottomNav({ active, onChange, onFab }:{
  active: Tab;
  onChange: (t:Tab)=>void;
  onFab?: ()=>void;
}){
  const Item = ({id, label, icon}:{id:Tab; label:string; icon:string}) => (
    <button
      className={`flex flex-col items-center flex-1 py-2 ${active===id ? "text-black" : "text-gray-500"}`}
      onClick={()=>onChange(id)}
    >
      <Icon name={icon} />
      <span className="text-[11px] mt-0.5">{label}</span>
    </button>
  );
  return (
    <div className="z-bottomnav fixed bottom-0 left-0 right-0">
      <div className="mx-auto max-w-md relative">
        <div className="absolute left-0 right-0 bottom-8 flex justify-center pointer-events-none">
          <button
            className="pointer-events-auto rounded-full w-14 h-14 flex items-center justify-center shadow-lg bg-black text-white"
            onClick={onFab}
            aria-label="Добавить"
          >
            <Icon name="plus" />
          </button>
        </div>
        <div className="rounded-t-2xl backdrop-blur bg-white/70 border-t border-white/50 shadow flex">
          <Item id="map" label="Карта" icon="map" />
          <Item id="feed" label="Лента" icon="feed" />
          <div className="w-14" /> {/* место под FAB */}
          <Item id="alerts" label="Оповещения" icon="alerts" />
          <Item id="profile" label="Профиль" icon="profile" />
        </div>
      </div>
    </div>
  );
}
