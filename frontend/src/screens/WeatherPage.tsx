import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";
import api from "../data/api";

type Slot={ name:string; lat:number; lng:number; };

export default function WeatherPage(){
  const [slots,setSlots]=useState<Slot[]>(()=> {
    const s = localStorage.getItem("weather_slots");
    return s ? JSON.parse(s) : [{name:"Москва",lat:55.7558,lng:37.6173}];
  });
  const [data,setData]=useState<any[]>([]);

  useEffect(()=> {
    Promise.all(slots.map(async s=>{
      try{ const w = await api.weather(s.lat,s.lng); return { ...s, w }; }catch{ return { ...s, w:null }; }
    })).then(setData);
  },[slots]);

  function addSlot(){
    const name = prompt("Название локации");
    const lat = Number(prompt("Широта")||"");
    const lng = Number(prompt("Долгота")||"");
    if(!name || Number.isNaN(lat) || Number.isNaN(lng)) return;
    const next=[...slots,{name,lat,lng}];
    setSlots(next); localStorage.setItem("weather_slots", JSON.stringify(next));
  }

  function del(i:number){
    const next=slots.slice(); next.splice(i,1); setSlots(next); localStorage.setItem("weather_slots", JSON.stringify(next));
  }

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center justify-between">
        <div className="flex items-center gap-2"><Icon name="weather"/><div className="font-semibold">Погода</div></div>
        <button onClick={addSlot} className="text-sm inline-flex items-center gap-1"><Icon name="plus"/>Локация</button>
      </div>
      <div className="p-3 grid gap-3">
        {data.map((s,i)=>(
          <div key={i} className="p-3 rounded-2xl bg-white/70 border border-white/50">
            <div className="flex items-center justify-between">
              <div className="font-semibold">{s.name}</div>
              <button onClick={()=>del(i)} className="text-xs text-gray-500">убрать</button>
            </div>
            <div className="text-sm text-gray-600">({s.lat}, {s.lng})</div>
            {s.w ? (
              <div className="mt-2 text-lg">
                Темп: {s.w?.temp ?? "—"}°C · Ветер: {s.w?.wind ?? "—"} м/с · Давление: {s.w?.pressure ?? "—"} гПа
              </div>
            ) : <div className="mt-2 text-gray-400">Нет данных</div>}
          </div>
        ))}
      </div>
    </div>
  );
}
