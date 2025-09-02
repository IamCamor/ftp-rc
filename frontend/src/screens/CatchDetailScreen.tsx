
import React from "react";
import { api } from "../data/api.extras";

export default function CatchDetailScreen({
  catchId, onClose, onOpenComments, onOpenPlace, onOpenSpecies, onOpenProfile
}:{
  catchId:number, onClose:()=>void,
  onOpenComments:()=>void,
  onOpenPlace:(placeId?:number,bbox?:[number,number,number,number])=>void,
  onOpenSpecies:(s:string)=>void,
  onOpenProfile:(uid:number)=>void
}){
  const [item,setItem]=React.useState<any>(null);
  React.useEffect(()=>{
    api.getJSON(`/catch/${catchId}`).then(setItem).catch(()=>{});
  },[catchId]);

  if(!item) return (
    <div className="fixed inset-0 z-[55] bg-black/20 backdrop-blur-sm flex items-center justify-center">
      <div className="bg-white rounded-2xl p-6 shadow-xl">Загрузка…</div>
    </div>
  );

  const media = item.media_url ? [item.media_url] : (item.photos||[]);
  const placeName = item.place_title || item.point_title;

  return (
    <div className="fixed inset-0 z-[55] bg-black/20 backdrop-blur-sm flex">
      <div className="m-auto w-full max-w-md bg-white rounded-2xl shadow-xl overflow-hidden">
        <div className="p-4 border-b flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full overflow-hidden bg-gray-100">
              {item.user_avatar_url ? <img src={item.user_avatar_url} className="w-full h-full object-cover"/> : null}
            </div>
            <button onClick={()=>onOpenProfile(item.user_id)} className="text-sm font-medium hover:underline">
              {item.user_name ?? ("User "+item.user_id)}
            </button>
          </div>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">✕</button>
        </div>

        {media?.length>0 && (
          <div className="w-full aspect-[4/3] bg-gray-100 overflow-hidden">
            <img src={media[0]} className="w-full h-full object-cover"/>
          </div>
        )}

        <div className="p-4 space-y-3">
          <div className="text-base">{item.caption}</div>

          <div className="flex flex-wrap gap-2 text-sm">
            {item.species && (
              <button onClick={()=>onOpenSpecies(item.species)}
                className="px-2 py-1 rounded-full bg-gray-100 hover:bg-gray-200">#{item.species}</button>
            )}
            {placeName && (
              <button onClick={()=>onOpenPlace(item.point_id)}
                className="px-2 py-1 rounded-full bg-gray-100 hover:bg-gray-200">📍 {placeName}</button>
            )}
          </div>

          <div className="flex items-center gap-4 text-sm text-gray-600">
            <button className="hover:text-pink-600" onClick={onOpenComments}>💬 Комментарии</button>
            <button className="hover:text-pink-600" onClick={()=>navigator.share?.({title:"Улов", url: location.href}).catch(()=>{})}>↗ Поделиться</button>
          </div>
        </div>
      </div>
    </div>
  );
}
