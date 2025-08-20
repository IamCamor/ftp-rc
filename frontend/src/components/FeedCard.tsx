import React from "react";
export type FeedItem={ id:number; author:{id:number;name:string;avatar?:string|null}; title?:string|null; text?:string|null; photo?:string|null; created_at?:string|null; likes?:number; comments?:number; };
export default function FeedCard({item,onLike,onOpen}:{item:FeedItem; onLike?:(id:number)=>void; onOpen?:(id:number)=>void;}){
  return (
    <div className="glass rounded-2xl p-3 mb-3">
      <div className="flex items-center gap-2 mb-2">
        <img src={item.author.avatar||"https://www.gravatar.com/avatar?d=mp"} alt="" className="w-8 h-8 rounded-full object-cover"/>
        <div className="flex-1">
          <div className="text-sm font-medium">{item.author.name}</div>
          {item.created_at && <div className="text-[11px] text-gray-500">{new Date(item.created_at).toLocaleString()}</div>}
        </div>
      </div>
      {item.title && <div className="font-medium mb-1">{item.title}</div>}
      {item.text && <div className="text-sm text-gray-700 mb-2">{item.text}</div>}
      {item.photo && <div className="overflow-hidden rounded-xl mb-2"><img src={item.photo} className="w-full h-auto" alt="" onClick={()=>onOpen?.(item.id)}/></div>}
      <div className="flex items-center gap-4 text-sm text-gray-700">
        <button onClick={()=>onLike?.(item.id)} className="flex items-center gap-1">❤️ <span>{item.likes??0}</span></button>
        <button className="flex items-center gap-1" onClick={()=>onOpen?.(item.id)}>💬 <span>{item.comments??0}</span></button>
      </div>
    </div>
  );
}
