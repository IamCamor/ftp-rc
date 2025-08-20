import React, { useEffect, useState } from "react";
import { getMe, logout } from "../data/api";
import { setToken } from "../data/auth";
type Me={ id:number; name:string; email:string; avatar?:string|null; stats?:{catches?:number;points?:number;likes?:number}};
export default function ProfileScreen(){
  const [me,setMe]=useState<Me|null>(null); const [err,setErr]=useState<string|null>(null);
  useEffect(()=>{ let c=false; (async()=>{ try{ const u=await getMe(); if(!c) setMe(u);}catch(e:any){ if(!c) setErr(e?.message||"Ошибка профиля"); }})(); return()=>{c=true}; },[]);
  const onLogout=async()=>{ try{ await logout(); }catch{} setToken(null); location.reload(); };
  if(err) return <div className="w-full h-full flex items-center justify-center text-red-600">{err}</div>;
  if(!me) return <div className="w-full h-full flex items-center justify-center text-gray-500">Загрузка…</div>;
  return (
    <div className="w-full h-full overflow-y-auto pb-24 pt-6 px-4">
      <div className="glass rounded-2xl p-4 flex items-center gap-3">
        <img src={me.avatar||"https://www.gravatar.com/avatar?d=mp"} className="w-16 h-16 rounded-full object-cover" alt=""/>
        <div className="flex-1"><div className="text-lg font-semibold">{me.name}</div><div className="text-sm text-gray-600">{me.email}</div></div>
        <button onClick={onLogout} className="text-sm text-red-600 underline">Выйти</button>
      </div>
      <div className="grid grid-cols-3 gap-3 mt-4">
        <div className="glass rounded-2xl p-3 text-center"><div className="text-xl font-semibold">{me.stats?.catches??0}</div><div className="text-xs text-gray-600">уловы</div></div>
        <div className="glass rounded-2xl p-3 text-center"><div className="text-xl font-semibold">{me.stats?.points??0}</div><div className="text-xs text-gray-600">точки</div></div>
        <div className="glass rounded-2xl p-3 text-center"><div className="text-xl font-semibold">{me.stats?.likes??0}</div><div className="text-xs text-gray-600">лайки</div></div>
      </div>
    </div>
  );
}
