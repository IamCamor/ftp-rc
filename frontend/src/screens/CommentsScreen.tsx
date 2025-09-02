
import React from "react";
import { api } from "../data/api.extras";

export default function CommentsScreen({catchId, onClose}:{catchId:number,onClose:()=>void}){
  const [items,setItems]=React.useState<any[]>([]);
  const [body,setBody]=React.useState("");
  const [loading,setLoading]=React.useState(false);

  const load = async ()=> {
    const res = await api.getJSON(`/catch/${catchId}/comments`);
    setItems(res?.data ?? res?.items ?? res ?? []);
  };
  React.useEffect(()=>{ load(); },[catchId]);

  const send = async ()=>{
    if(!body.trim()) return;
    setLoading(true);
    try{
      await api.postJSON(`/catch/${catchId}/comments`, { body });
      setBody("");
      await load();
    }finally{
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-[60] backdrop-blur-sm bg-black/20 flex">
      <div className="m-auto w-full max-w-md bg-white rounded-2xl shadow-xl overflow-hidden">
        <div className="p-4 border-b flex items-center justify-between">
          <div className="font-semibold">Комментарии</div>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">✕</button>
        </div>
        <div className="max-h-[60vh] overflow-auto p-4 space-y-4">
          {items.map((c:any)=>(
            <div key={c.id} className="flex gap-3">
              <div className="w-9 h-9 rounded-full bg-gray-200 overflow-hidden">
                {c.user_avatar_url ? <img src={c.user_avatar_url} alt="" className="w-full h-full object-cover"/> : null}
              </div>
              <div>
                <div className="text-sm font-medium">{c.user_name ?? "User "+c.user_id}</div>
                <div className="text-sm text-gray-700">{c.body}</div>
              </div>
            </div>
          ))}
          {items.length===0 && <div className="text-center text-gray-500 text-sm">Нет комментариев</div>}
        </div>
        <div className="p-4 border-t flex gap-2">
          <input value={body} onChange={e=>setBody(e.target.value)} placeholder="Написать комментарий..."
            className="flex-1 bg-gray-50 border rounded-xl px-3 py-2 outline-none focus:ring-2 focus:ring-pink-300"/>
          <button disabled={loading} onClick={send}
            className="px-4 py-2 rounded-xl bg-pink-600 text-white disabled:opacity-60">Отправить</button>
        </div>
      </div>
    </div>
  );
}
