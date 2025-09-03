import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import api from "../data/api";
import Icon from "../components/Icon";

export default function PlaceDetailPage(){
  const { id } = useParams();
  const [data,setData]=useState<any>(null);

  useEffect(()=>{ if(id) api.placeById(id).then(setData).catch(()=>{}); },[id]);

  if(!data) return <div className="p-4 text-gray-500">Загрузка…</div>;

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <a href="/map" className="mr-1"><Icon name="back"/></a>
        <div className="font-semibold">Место</div>
      </div>
      <div className="p-4 space-y-3">
        <div className="text-xl font-semibold">{data.title||"Точка"}</div>
        {data.photo_url && <img src={data.photo_url} className="w-full rounded-2xl border border-white/50"/>}
        <div className="text-sm text-gray-600">Категория: {data.category||data.type||"—"}</div>
        <div className="text-sm text-gray-600">Координаты: {data.lat}, {data.lng}</div>
        <a href={`/feed?place=${data.id}`} className="inline-flex items-center gap-2 px-3 py-2 rounded-xl bg-black text-white">
          <Icon name="feed"/> Уловы этого места
        </a>
      </div>
    </div>
  );
}
