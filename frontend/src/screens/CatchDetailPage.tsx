import React,{useEffect,useState} from "react";
import {api} from "../lib/api";
import {Input, Button, Card, CardContent} from "../components/ui";
import {toast} from "../lib/toast";

export default function CatchDetailPage({id}:{id:number}){
  const [item,setItem]=useState<any>(null);
  const [comments,setComments]=useState<any[]>([]);
  const [body,setBody]=useState("");

  useEffect(()=>{ (async()=>{
    try{
      const j:any=await api.catchById(id);
      setItem(j.item); setComments(j.comments||[]);
    }catch{ toast('Не найдено'); history.back(); }
  })(); },[id]);

  const send=async()=>{
    if(!body.trim()) return;
    try{ await api.comment(id,{body, user_id:1}); setBody(""); const j:any=await api.catchById(id); setComments(j.comments||[]); }
    catch{ toast('Ошибка'); }
  };

  if(!item) return <div className="p-6 text-center text-gray-500">Загрузка…</div>;
  return <div className="p-3 pb-28 max-w-2xl mx-auto space-y-3">
    <Card><CardContent>
      <div className="flex items-center gap-3">
        <img src={item.user_avatar||'/avatar.svg'} className="w-9 h-9 rounded-full object-cover" onClick={()=>location.hash=`#/u/${item.user_id}`}/>
        <div className="flex-1">
          <div className="font-medium cursor-pointer" onClick={()=>location.hash=`#/u/${item.user_id}`}>{item.user_name||'Рыбак'}</div>
          <div className="text-xs text-gray-500">{new Date(item.created_at).toLocaleString()}</div>
        </div>
        <button className="text-sm text-gray-600" onClick={()=>navigator.clipboard?.writeText(location.href)}>Поделиться</button>
      </div>
      {item.photo_url && <img src={item.photo_url} className="w-full max-h-[70vh] object-cover rounded-xl mt-3" />}
      <div className="mt-3 flex flex-wrap gap-3 text-sm">
        {item.species && <span className="px-3 py-1 border rounded-full cursor-pointer" onClick={()=>location.hash=`#/?species=${encodeURIComponent(item.species)}`}>🐟 {item.species}</span>}
        <span className="px-3 py-1 border rounded-full cursor-pointer" onClick={()=>location.hash=`#/feed?near=${item.lat},${item.lng}`}>📍 место</span>
      </div>
      {item.notes && <div className="mt-3">{item.notes}</div>}
      <div className="mt-3 text-sm text-gray-700 flex items-center gap-4">
        <span>❤️ {item.likes_count}</span>
        <span>💬 {item.comments_count}</span>
      </div>
    </CardContent></Card>

    <Card><CardContent>
      <div className="text-sm font-medium mb-2">Комментарии</div>
      <div className="space-y-3">
        {comments.map(c=><div key={c.id} className="flex items-start gap-3">
          <img src={c.user_avatar||'/avatar.svg'} className="w-7 h-7 rounded-full object-cover"/>
          <div>
            <div className="text-sm font-medium">{c.user_name}</div>
            <div className="text-sm">{c.body}</div>
          </div>
        </div>)}
        {comments.length===0 && <div className="text-gray-500 text-sm">Пока нет комментариев</div>}
      </div>
      <div className="flex gap-2 mt-4">
        <Input placeholder="Написать комментарий…" value={body} onChange={e=>setBody(e.target.value)} />
        <Button onClick={send}>Отпр.</Button>
      </div>
    </CardContent></Card>
  </div>;
}
