import React, { useEffect, useState } from "react";
import FeedCard, { FeedItem } from "../components/FeedCard";
import { fetchFeed, likePost } from "../data/api";
import SearchBar from "../components/SearchBar";
import { useDebounce } from "../utils/useDebounce";
export default function FeedScreen(){
  const [items,setItems]=useState<FeedItem[]>([]); const [q,setQ]=useState(""); const [err,setErr]=useState<string|null>(null); const [loading,setLoading]=useState(false);
  const dq=useDebounce(q,300);
  useEffect(()=>{ let c=false; (async()=>{ setLoading(true); setErr(null);
    try{ const data=await fetchFeed({q:dq,limit:50}); if(!c) setItems(data); }catch(e:any){ if(!c) setErr(e?.message||"Ошибка загрузки ленты"); }finally{ setLoading(false); }
  })(); return()=>{c=true}; },[dq]);
  const onLike=async(id:number)=>{ try{ await likePost(id); setItems(p=>p.map(x=>x.id===id?{...x,likes:(x.likes??0)+1}:x)); }catch{} };
  return (
    <div className="w-full h-full overflow-y-auto pb-24 pt-16 px-3">
      <SearchBar value={q} onChange={setQ}/>
      {err && <div className="mt-16 text-sm text-red-600">{err}</div>}
      {!err && loading && <div className="mt-16 text-gray-500">Загрузка…</div>}
      {!loading && !items.length && <div className="mt-16 text-gray-500">Пока пусто</div>}
      <div className="mt-2">{items.map(it=><FeedCard key={it.id} item={it} onLike={onLike} onOpen={(id)=>alert(`Открыть пост #${id}`)}/>)}</div>
    </div>
  );
}
