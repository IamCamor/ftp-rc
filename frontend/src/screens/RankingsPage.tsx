import React, { useEffect, useState } from 'react';
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

export default function RankingsPage(){
  const [range,setRange]=useState<'week'|'month'|'all'>('month');
  const {data,loading}=useFetch(`/api/v1/rating?range=${range}`);
  return (
    <div className="min-h-screen bg-gray-50">
      <HeaderBar/>
      <div className="h-16" />
      <div className="px-3 py-2">
        <div className="flex gap-2 mb-3">
          {(['week','month','all'] as const).map(r=>(
            <button key={r} onClick={()=>setRange(r)} className={`px-3 py-1 rounded-xl border ${range===r?'bg-black text-white':'bg-white/60'}`}>{r==='week'?'Неделя':r==='month'?'Месяц':'Все время'}</button>
          ))}
        </div>
        {loading && <div className="text-gray-500">Загрузка...</div>}
        <div className="flex flex-col gap-2">
          {data?.items?.map((u:any)=>(
            <UserCard key={u.user_id} name={u.name || 'Без имени'} photo={u.photo_url}
              right={<div className="text-sm text-gray-600 text-right">
                <div><b>{u.catches_count}</b> уловов</div>
                <div className="text-xs">{u.total_weight?.toFixed?.(1) || 0} кг</div>
              </div>}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
