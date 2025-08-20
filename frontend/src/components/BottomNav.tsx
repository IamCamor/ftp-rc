import React from "react";
import { Home, MapPin, Bell, User, Plus } from "lucide-react";
type Tab="feed"|"map"|"alerts"|"profile";
export default function BottomNav({onFab,active,onChange}:{onFab:()=>void; active:Tab; onChange:(t:Tab)=>void}) {
  const cn=(t:Tab)=>"flex flex-col items-center "+(active===t?"text-black":"text-gray-600");
  return (
    <div className="fixed bottom-0 left-0 w-full h-16 glass-soft flex items-center justify-around z-[1200]">
      <button className={cn("feed")} onClick={()=>onChange("feed")} aria-label="Лента"><Home size={22}/><span className="text-[11px]">Лента</span></button>
      <button className={cn("map")} onClick={()=>onChange("map")} aria-label="Карта"><MapPin size={22}/><span className="text-[11px]">Карта</span></button>
      <button onClick={onFab} aria-label="Добавить" className="absolute -top-6 left-1/2 -translate-x-1/2 rounded-full p-4 shadow-lg grad-ig text-white"><Plus size={26}/></button>
      <button className={cn("alerts")} onClick={()=>onChange("alerts")} aria-label="Уведомления"><Bell size={22}/><span className="text-[11px]">Уведомл.</span></button>
      <button className={cn("profile")} onClick={()=>onChange("profile")} aria-label="Профиль"><User size={22}/><span className="text-[11px]">Профиль</span></button>
    </div>
  );
}
