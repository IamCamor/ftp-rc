import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";

type CatchItem={ id:number; species?:string; media_url?:string; created_at:string; likes_count?:number; comments_count?:number; };

async function fetchMy(): Promise<CatchItem[]>{
  try{
    const base = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
    const r = await fetch(`${base}/catches?me=1&limit=50`, { credentials:"include" });
    if(!r.ok) return [];
    const j = await r.json();
    return j?.items || [];
  }catch{ return []; }
}

export default function MyCatchesPage(){
  const [items,setItems]=useState<CatchItem[]>([]);
  useEffect(()=>{ fetchMy().then(setItems); },[]);
  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="photo"/><div className="font-semibold">Мои уловы</div>
      </div>
      <div className="p-3 grid grid-cols-2 gap-3">
        {items.map(it=>(
          <a key={it.id} href={`/catch/${it.id}`} className="block rounded-xl overflow-hidden bg-white/70 border border-white/50">
            {it.media_url ? (
              <img src={it.media_url} className="w-full aspect-square object-cover"/>
            ) : (
              <div className="w-full aspect-square flex items-center justify-center text-gray-400"><Icon name="photo"/></div>
            )}
            <div className="p-2 text-sm flex items-center justify-between">
              <span>{it.species||"Не указано"}</span>
              <span className="text-gray-500 inline-flex items-center gap-2">
                <span className="inline-flex items-center gap-1"><Icon name="like" size={18}/>{it.likes_count||0}</span>
                <span className="inline-flex items-center gap-1"><Icon name="comment" size={18}/>{it.comments_count||0}</span>
              </span>
            </div>
          </a>
        ))}
      </div>
    </div>
  );
}
