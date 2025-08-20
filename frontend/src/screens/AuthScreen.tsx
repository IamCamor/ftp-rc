import React, { useState } from "react";
import { login, registerUser } from "../data/api";
import { setToken } from "../data/auth";
export default function AuthScreen({onClose}:{onClose?:()=>void}){
  const [mode,setMode]=useState<"login"|"register">("login");
  const [email,setEmail]=useState(""); const [password,setPassword]=useState(""); const [displayName,setDisplayName]=useState("");
  const [error,setError]=useState<string|null>(null); const [loading,setLoading]=useState(false);
  const submit=async(e:React.FormEvent)=>{ e.preventDefault(); setLoading(true); setError(null);
    try{ const {token} = mode==="login" ? await login({email,password}) : await registerUser({email,password,name:displayName});
      setToken(token); onClose?.(); } catch(err:any){ setError(err?.message||"Ошибка"); } finally{ setLoading(false); }
  };
  return (
    <div className="fixed inset-0 z-[2000] flex items-center justify-center bg-black/30">
      <div className="glass rounded-2xl w-[92%] max-w-md p-5">
        <div className="flex justify-between items-center mb-3">
          <h3 className="text-lg font-semibold">{mode==="login"?"Войти":"Регистрация"}</h3>
          <button onClick={onClose} className="text-gray-500">✕</button>
        </div>
        <form onSubmit={submit} className="space-y-3">
          {mode==="register" && (<div><label className="text-sm text-gray-700">Отображаемое имя</label>
            <input className="w-full bg-white/60 rounded-xl p-2 outline-none" value={displayName} onChange={(e)=>setDisplayName(e.target.value)} required/></div>)}
          <div><label className="text-sm text-gray-700">Email</label>
            <input type="email" className="w-full bg-white/60 rounded-xl p-2 outline-none" value={email} onChange={(e)=>setEmail(e.target.value)} required/></div>
          <div><label className="text-sm text-gray-700">Пароль</label>
            <input type="password" className="w-full bg-white/60 rounded-xl p-2 outline-none" value={password} onChange={(e)=>setPassword(e.target.value)} required/></div>
          {error && <div className="text-sm text-red-600">{error}</div>}
          <button disabled={loading} className="w-full grad-ig text-white rounded-xl py-2 shadow">{loading?"…":(mode==="login"?"Войти":"Зарегистрироваться")}</button>
        </form>
        <div className="text-center mt-3 text-sm">
          {mode==="login"? <>Нет аккаунта? <button className="underline" onClick={()=>setMode("register")}>Создать</button></>
                         : <>Уже с нами? <button className="underline" onClick={()=>setMode("login")}>Войти</button></>}
        </div>
      </div>
    </div>
  );
}
