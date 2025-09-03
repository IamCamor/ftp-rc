import React, {useEffect,useState} from 'react';
import HeaderBar from '../components/HeaderBar';
import UserCard from '../components/UserCard';

function useFetch(url:string){
  const [data,setData]=useState<any>(null);
  const [loading,setLoading]=useState(true);
  const [error,setError]=useState<string|null>(null);
  useEffect(()=>{
    let alive=true;
    setLoading(true);
    fetch(url).then(r=>r.json()).then(j=>{ if(!alive) return; setData(j); setLoading(false); })
      .catch(e=>{ if(!alive) return; setError(String(e)); setLoading(false); });
    return ()=>{ alive=false };
  },[url]);
  return {data,loading,error};
}

export default function FriendsPage(){
  const [tab,setTab]=useState<'mutual'|'following'|'followers'>('mutual');
  const {data:friends,loading}=useFetch(`/api/v1/friends?scope=${tab}`);
  const {data:suggest}=useFetch(`/api/v1/friends/suggest?limit=10`);
  return (
    <div className="min-h-screen bg-gray-50">
      <HeaderBar/>
      <div className="h-16" />
      <div className="px-3 py-2">
        <div className="flex gap-2 mb-3">
          {(['mutual','following','followers'] as const).map(r=>(
            <button key={r} onClick={()=>setTab(r)} className={`px-3 py-1 rounded-xl border ${tab===r?'bg-black text-white':'bg-white/60'}`}>
              {r==='mutual'?'Друзья':r==='following'?'Подписки':'Подписчики'}
            </button>
          ))}
        </div>

        {loading && <div className="text-gray-500">Загрузка...</div>}
        <div className="flex flex-col gap-2 mb-6">
          {friends?.items?.map((u:any)=>(
            <UserCard key={`f-${u.id}`} name={u.name || 'Без имени'} photo={u.photo_url}
              right={<button className="text-xs px-2 py-1 border rounded-xl bg-white/60">Открыть</button>}
            />
          ))}
        </div>

        <div className="text-sm font-medium mb-2">Возможно, вы знакомы</div>
        <div className="flex flex-col gap-2">
          {suggest?.items?.map((u:any)=>(
            <UserCard key={`s-${u.id}`} name={u.name || 'Без имени'} photo={u.photo_url}
              right={<button className="text-xs px-2 py-1 border rounded-xl bg-white/60">Подписаться</button>}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
