// src/screens/CatchDetailPage.tsx
import React, { useEffect, useState } from "react";
import HeaderBar from "../components/HeaderBar";
import { api } from "../api";

export default function CatchDetailPage({ id }: { id: string }) {
  const [data, setData] = useState<any>(null);
  const [comment, setComment] = useState("");

  useEffect(() => {
    api.catchById(id).then(setData).catch(()=>{});
  }, [id]);

  const addComment = async ()=>{
    try{
      await api.addComment(id, comment);
      setComment("");
      const fresh = await api.catchById(id);
      setData(fresh);
    }catch(e:any){ alert("Ошибка комментария: "+(e?.message||e)); }
  };

  if (!data) return <div className="text-center mt-16">Загрузка…</div>;

  return (
    <div className="w-full h-full">
      <HeaderBar title={data?.species || "Улов"} />
      <div className="mx-auto max-w-md px-3 mt-16 pb-28">
        <div className="glass">
          {data.media_url && <img src={data.media_url} className="w-full h-72 object-cover rounded-t-2xl" />}
          <div className="p-4 space-y-2">
            <div className="text-sm text-gray-600">{new Date(data.created_at).toLocaleString()}</div>
            <div className="font-semibold">{data.user_name}</div>
            <div className="text-sm">{data.caption}</div>
            <div className="text-sm text-gray-700">❤ {data.likes_count ?? 0} · 💬 {data.comments_count ?? 0}</div>

            <div className="mt-2">
              <div className="font-medium mb-1">Комментарии</div>
              {(data.comments || []).map((c:any)=>(
                <div key={c.id} className="text-sm text-gray-700 py-1 border-t border-white/60">{c.text}</div>
              ))}
              <div className="flex gap-2 mt-2">
                <input className="flex-1 glass px-3 py-2" placeholder="Ваш комментарий" value={comment} onChange={e=>setComment(e.target.value)} />
                <button onClick={addComment} className="px-3 rounded-xl bg-pink-500 text-white">Отпр.</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
