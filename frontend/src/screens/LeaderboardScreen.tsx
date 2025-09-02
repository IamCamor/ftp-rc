
import React from "react";
import { api } from "../data/api.extras";

export default function LeaderboardScreen({onOpenUser}:{onOpenUser:(uid:number)=>void}){
  const [period,setPeriod]=React.useState<"week"|"month"|"all">("week");
  const [metric,setMetric]=React.useState<"catches"|"weight"|"likes">("catches");
  const [items,setItems]=React.useState<any[]>([]);
  React.useEffect(()=>{
    api.getJSON(`/leaderboard?period=${period}&metric=${metric}`).then(setItems).catch(()=>setItems([]));
  },[period,metric]);

  return (
    <div className="w-full h-full p-4">
      <div className="max-w-md mx-auto space-y-3">
        <div className="backdrop-blur-md bg-white/60 border border-white/40 rounded-2xl p-3 shadow flex gap-2">
          <select value={period} onChange={e=>setPeriod(e.target.value as any)} className="flex-1 rounded-xl border px-3 py-2 bg-white/80">
            <option value="week">Неделя</option>
            <option value="month">Месяц</option>
            <option value="all">За всё время</option>
          </select>
          <select value={metric} onChange={e=>setMetric(e.target.value as any)} className="flex-1 rounded-xl border px-3 py-2 bg-white/80">
            <option value="catches">По уловам</option>
            <option value="weight">По весу</option>
            <option value="likes">По лайкам</option>
          </select>
        </div>

        <div className="backdrop-blur-md bg-white/60 border border-white/40 rounded-2xl p-2 shadow divide-y">
          {items.map((u:any,idx:number)=>(
            <button key={u.user_id ?? u.id ?? idx} onClick={()=>onOpenUser(u.user_id ?? u.id)} className="w-full flex items-center gap-3 p-3 hover:bg-white/60">
              <div className="w-10 text-center font-semibold">{idx+1}</div>
              <div className="w-10 h-10 rounded-full bg-gray-200 overflow-hidden">
                {u.avatar_url ? <img src={u.avatar_url} className="w-full h-full object-cover"/>:null}
              </div>
              <div className="flex-1 text-left">
                <div className="font-medium">{u.name ?? ("User "+(u.user_id ?? u.id))}</div>
                <div className="text-xs text-gray-500">
                  {metric==="catches" && `${u.catches_count ?? 0} уловов`}
                  {metric==="weight" && `${u.weight_total ?? 0} кг`}
                  {metric==="likes" && `${u.likes_count ?? 0} лайков`}
                </div>
              </div>
            </button>
          ))}
          {items.length===0 && <div className="p-6 text-center text-gray-500 text-sm">Пока пусто</div>}
        </div>
      </div>
    </div>
  );
}
