import React, { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import api from "../data/api";
import Icon from "../components/Icon";

export default function CatchDetailPage(){
  const { id } = useParams();
  const [data,setData]=useState<any>(null);
  const [comment,setComment]=useState("");

  useEffect(()=>{ if(id) api.catchById(id).then(setData).catch(()=>{}); },[id]);

  async function sendComment(){
    if(!id || !comment.trim()) return;
    try{ await api.addComment(id, comment.trim()); setComment(""); const j=await api.catchById(id); setData(j); }catch{}
  }
  async function like(){
    if(!id) return; try{ await api.toggleLike(id); const j=await api.catchById(id); setData(j);}catch{}
  }

  if(!data) return <div className="p-4 text-gray-500">Загрузка…</div>;

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <a href="/feed" className="mr-1"><Icon name="back"/></a>
        <div className="font-semibold">Улов</div>
      </div>

      <article className="p-3 space-y-3">
        <header className="flex items-center gap-2">
          <img src={data.user_avatar||"/assets/default-avatar.png"} className="w-8 h-8 rounded-full object-cover"/>
          <a href={`/u/${data.user_id}`} className="font-medium hover:underline">{data.user_name}</a>
          <span className="text-xs text-gray-500 ml-auto">{new Date(data.created_at).toLocaleString()}</span>
        </header>

        <div className="rounded-2xl overflow-hidden bg-white/70 border border-white/50">
          {data.media_url ? <img src={data.media_url} className="w-full object-cover max-h-[70vh]" /> : (
            <div className="w-full aspect-video flex items-center justify-center text-gray-400"><Icon name="photo"/></div>
          )}
        </div>

        <div className="text-sm">
          <div><b>Вид:</b> {data.species||"—"}</div>
          <div><b>Длина:</b> {data.length||"—"} см</div>
          <div><b>Вес:</b> {data.weight||"—"} г</div>
          {!!data.place_id && (
            <div className="mt-2">
              <a className="inline-flex items-center gap-1 text-blue-600 hover:underline" href={`/place/${data.place_id}`}><Icon name="pin"/> Место поимки</a>
            </div>
          )}
        </div>

        <footer className="flex items-center gap-4 text-sm">
          <button className="inline-flex items-center gap-1" onClick={like}><Icon name="like"/>{data.likes_count||0}</button>
          <span className="inline-flex items-center gap-1"><Icon name="comment"/>{data.comments_count||0}</span>
          <button className="inline-flex items-center gap-1" onClick={()=>{
            if (navigator.share) navigator.share({ title:"Улов", url: window.location.href }).catch(()=>{});
          }}><Icon name="share"/>Поделиться</button>
        </footer>

        <section className="mt-3">
          <div className="font-semibold mb-2">Комментарии</div>
          <div className="space-y-2">
            {(data.comments||[]).map((c:any)=>(
              <div key={c.id} className="p-2 rounded-xl bg-white/70 border border-white/50">
                <div className="text-sm"><b>{c.user_name||"Гость"}:</b> {c.body}</div>
                <div className="text-xs text-gray-500 mt-1">{new Date(c.created_at).toLocaleString()}</div>
              </div>
            ))}
          </div>
          <div className="mt-2 flex gap-2">
            <input className="input flex-1" placeholder="Ваш комментарий…" value={comment} onChange={e=>setComment(e.target.value)} />
            <button className="px-3 rounded-xl bg-black text-white" onClick={sendComment}><Icon name="send"/>Отпр</button>
          </div>
        </section>
      </article>
    </div>
  );
}
