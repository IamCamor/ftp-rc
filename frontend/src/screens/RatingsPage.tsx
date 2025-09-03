import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";

type Row={ user_id:number; name:string; handle?:string; avatar?:string; score:number; rank:number; };

async function fetchRatings(): Promise<Row[]>{
  try{
    const base = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
    const r = await fetch(`${base}/ratings`, { credentials:"include" });
    if(!r.ok) return [];
    const j = await r.json();
    return j?.items || [];
  }catch{ return []; }
}

export default function RatingsPage(){
  const [items,setItems]=useState<Row[]>([]);
  useEffect(()=>{ fetchRatings().then(setItems); },[]);
  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center justify-between">
        <div className="flex items-center gap-2"><Icon name="rating"/><div className="font-semibold">Рейтинги</div></div>
        <a href="/profile" className="text-sm text-blue-600">Мой профиль</a>
      </div>
      <div className="p-3">
        {items.map(row=>(
          <a href={`/u/${row.user_id}`} key={row.user_id} className="flex items-center gap-3 p-3 mb-2 rounded-xl bg-white/70 backdrop-blur border border-white/40 hover:bg-white/90">
            <div className="w-8 text-center font-semibold">{row.rank}</div>
            <img src={row.avatar||"/assets/default-avatar.png"} className="w-10 h-10 rounded-full object-cover"/>
            <div className="flex-1">
              <div className="font-medium">{row.name}</div>
              <div className="text-xs text-gray-500">@{row.handle||("user"+row.user_id)}</div>
            </div>
            <div className="text-sm font-semibold">{row.score}</div>
          </a>
        ))}
      </div>
    </div>
  );
}
