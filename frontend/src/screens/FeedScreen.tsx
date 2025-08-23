import React,{useEffect,useRef,useState} from "react";
import {api} from "../lib/api";
import {toast} from "../lib/toast";

type FeedItem = {
  id:number,user_id:number,user_name:string,user_avatar?:string|null,
  lat:number,lng:number,species?:string|null,length?:number|null,weight?:number|null,
  notes?:string|null,photo_url?:string|null, created_at:string,
  likes_count:number, comments_count:number
};
export default function FeedScreen({placeId}:{placeId?:number}){
  const [items,setItems]=useState<FeedItem[]>([]);
  const [loading,setLoading]=useState(false);
  const [offset,setOffset]=useState(0);
  const doneRef=useRef(false);

  const load=async()=>{
    if(loading||doneRef.current) return; setLoading(true);
    try{
      const q:any={limit:20,offset};
      if(placeId) q.place_id=placeId;
      const j:any=await api.feed(q);
      const next=j.next_offset ?? (offset+(j.items?.length||0));
      setItems(prev=>[...prev,...(j.items||[])]);
      setOffset(next);
      if(!j.items || j.items.length===0) doneRef.current=true;
    }catch{ toast('Ошибка загрузки ленты'); }
    finally{ setLoading(false); }
  };

  useEffect(()=>{ // init
    setItems([]); setOffset(0); doneRef.current=false; load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  },[placeId]);

  useEffect(()=>{ // inf scroll
    const onScroll=()=>{
      if((window.innerHeight+window.scrollY)>=document.body.offsetHeight-400) load();
    };
    window.addEventListener('scroll',onScroll); return ()=>window.removeEventListener('scroll',onScroll);
  },[load]);

  return <div className="p-3 pb-28 max-w-2xl mx-auto space-y-3">
    {items.map(it=><div key={it.id} className="rounded-2xl bg-white/70 backdrop-blur border border-white/60 shadow-md overflow-hidden">
      <div className="flex items-center gap-3 px-4 py-3">
        <img src={it.user_avatar||'/avatar.svg'} className="w-9 h-9 rounded-full object-cover" onError={(e:any)=>e.currentTarget.src='/avatar.svg'}/>
        <div className="flex-1">
          <div className="font-medium cursor-pointer" onClick={()=>location.hash=`#/u/${it.user_id}`}>{it.user_name||'Рыбак'}</div>
          <div className="text-xs text-gray-500">{new Date(it.created_at).toLocaleString()}</div>
        </div>
        <button className="text-sm text-gray-600" onClick={()=>shareCatch(it.id)}>Поделиться</button>
      </div>
      {it.photo_url && <img src={it.photo_url} className="w-full max-h-[60vh] object-cover" />}
      <div className="px-4 py-3 text-sm space-y-2">
        <div className="flex flex-wrap gap-3">
          {it.species && <span className="px-3 py-1 rounded-full border cursor-pointer" onClick={()=>location.hash=`#/?species=${encodeURIComponent(it.species!)}`}>🐟 {it.species}</span>}
          <span className="px-3 py-1 rounded-full border cursor-pointer" onClick={()=>openNearby(it.lat,it.lng)}>📍 место</span>
        </div>
        {it.notes && <div>{it.notes}</div>}
        <div className="flex items-center justify-between pt-2 text-sm text-gray-700">
          <div className="flex items-center gap-4">
            <button onClick={()=>like(it.id)} title="Нравится">❤️ {it.likes_count}</button>
            <button onClick={()=>location.hash=`#/catch/${it.id}`} title="Комментарии">💬 {it.comments_count}</button>
          </div>
          <div className="flex items-center gap-4">
            <button onClick={()=>follow(it.user_id)}>➕ Подписаться</button>
            <button onClick={()=>report(it.id)} className="text-red-600">Пожаловаться</button>
          </div>
        </div>
      </div>
    </div>)}
    {loading && <div className="text-center text-gray-500 py-6">Загрузка…</div>}
    {!loading && items.length===0 && <div className="text-center text-gray-500 py-12">Пока пусто</div>}
  </div>;
}

function shareCatch(id:number){
  const link = `${location.origin}/#/catch/${id}`;
  if((navigator as any).share) (navigator as any).share({title:'Улов',url:link});
  else navigator.clipboard?.writeText(link);
}

async function like(id:number){
  try{ await fetch(`${(import.meta as any).env?.VITE_API_BASE||'https://api.fishtrackpro.ru'}/api/v1/catch/${id}/like`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({user_id:1})}); }catch{}
  location.hash=`#/catch/${id}`; // откроем деталь (для честного пересчёта)
}

async function report(id:number){
  alert('Жалоба отправлена (демо)');
}

async function follow(uid:number){
  try{ await fetch(`${(import.meta as any).env?.VITE_API_BASE||'https://api.fishtrackpro.ru'}/api/v1/follow/${uid}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({user_id:1})}); }catch{}
  alert('Готово');
}

function openNearby(lat:number,lng:number){
  // эмулируем переход к ленте по ближайшему месту: передадим координаты в хэше
  location.hash=`#/feed?near=${lat.toFixed(5)},${lng.toFixed(5)}`;
}
