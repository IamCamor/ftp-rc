import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";

type Friend = { id:number; name:string; handle?:string; avatar?:string; followed?:boolean; };

async function fetchFriends(): Promise<Friend[]>{
  try{
    const base = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
    const r = await fetch(`${base}/friends`, { credentials:"include" });
    if(!r.ok) return [];
    const j = await r.json();
    return j?.items || [];
  }catch{ return []; }
}

export default function FriendsPage(){
  const [items,setItems]=useState<Friend[]>([]);
  const [loading,setLoading]=useState(true);
  useEffect(()=>{ fetchFriends().then(d=>{setItems(d);setLoading(false);}); },[]);
  if(loading) return <div className="p-4 text-gray-500">Загрузка…</div>;
  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="friends"/><div className="font-semibold">Друзья</div>
      </div>
      <ul className="divide-y divide-gray-100">
        {items.map(f=>(
          <li key={f.id} className="p-3 flex items-center gap-3">
            <img src={f.avatar||"/assets/default-avatar.png"} className="w-10 h-10 rounded-full object-cover" />
            <div className="flex-1">
              <div className="font-medium">{f.name}</div>
              <div className="text-xs text-gray-500">@{f.handle||("user"+f.id)}</div>
            </div>
            <a href={`/u/${f.id}`} className="text-sm text-blue-600 hover:underline">Профиль</a>
          </li>
        ))}
      </ul>
    </div>
  );
}
