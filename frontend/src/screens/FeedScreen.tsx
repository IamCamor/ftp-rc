import React, { useEffect, useRef, useState } from "react";
import api from "../data/api";
import Icon from "../components/Icon";

type FeedItem = {
  id:number; user_id:number; user_name:string; user_avatar?:string;
  species?:string; media_url?:string; created_at:string;
  likes_count?:number; comments_count?:number;
};

export default function FeedScreen(){
  const [items,setItems]=useState<FeedItem[]>([]);
  const [offset,setOffset]=useState(0);
  const [loading,setLoading]=useState(false);
  const [done,setDone]=useState(false);
  const sentinel = useRef<HTMLDivElement|null>(null);

  async function load(){
    if(loading||done) return;
    setLoading(true);
    try{
      const j:any = await api.feed(`?limit=10&offset=${offset}`);
      const list:FeedItem[] = j?.items || [];
      setItems(prev=>[...prev, ...list]);
      setOffset(prev=>prev+list.length);
      if(list.length<10) setDone(true);
    } finally {
      setLoading(false);
    }
  }

  useEffect(()=>{ load(); },[]);
  useEffect(()=>{
    const el = sentinel.current; if(!el) return;
    const io = new IntersectionObserver(([e])=> { if(e.isIntersecting) load(); }, {rootMargin:"200px"});
    io.observe(el); return ()=>io.disconnect();
  },[sentinel.current, loading, done]);

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center justify-between">
        <div className="font-semibold">Лента</div>
        <a href="/weather" className="text-sm inline-flex items-center gap-1"><Icon name="weather"/> Погода</a>
      </div>

      <div className="divide-y divide-gray-100">
        {items.map(it=>(
          <article key={it.id} className="p-3 space-y-2">
            <header className="flex items-center gap-2">
              <img src={it.user_avatar||"/assets/default-avatar.png"} className="w-8 h-8 rounded-full object-cover"/>
              <a href={`/u/${it.user_id}`} className="font-medium hover:underline">{it.user_name}</a>
              <span className="text-xs text-gray-500 ml-auto">{new Date(it.created_at).toLocaleString()}</span>
            </header>
            <a href={`/catch/${it.id}`} className="block rounded-2xl overflow-hidden bg-white/70 border border-white/50">
              {it.media_url ? (
                <img src={it.media_url} className="w-full object-cover max-h-[70vh]" />
              ) : (
                <div className="w-full aspect-video flex items-center justify-center text-gray-400"><Icon name="photo"/></div>
              )}
            </a>
            <footer className="flex items-center gap-4 text-sm">
              <button className="inline-flex items-center gap-1"><Icon name="like"/>{it.likes_count||0}</button>
              <a className="inline-flex items-center gap-1" href={`/catch/${it.id}`}><Icon name="comment"/>{it.comments_count||0}</a>
              <button className="inline-flex items-center gap-1" onClick={()=>{
                if (navigator.share) navigator.share({ title:"Улов", url: `/catch/${it.id}` }).catch(()=>{});
              }}><Icon name="share"/>Поделиться</button>
            </footer>
          </article>
        ))}
      </div>

      <div ref={sentinel} className="h-12 flex items-center justify-center text-gray-400">
        {done ? "Это всё на сегодня" : (loading ? "Загрузка..." : "")}
      </div>
    </div>
  );
}
