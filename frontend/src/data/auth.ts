import { useEffect, useState } from "react";
const TOKEN_KEY="ftp_token";
export const getToken=()=>localStorage.getItem(TOKEN_KEY);
export const setToken=(t:string|null)=>t?localStorage.setItem(TOKEN_KEY,t):localStorage.removeItem(TOKEN_KEY);
export const authHeader=()=>{const t=getToken(); return t?{Authorization:`Bearer ${t}`}:{}}; 
export function useAuthState(){ const [isAuthed,setAuthed]=useState(!!getToken());
  useEffect(()=>{const on=()=>setAuthed(!!getToken()); window.addEventListener("storage",on); return()=>window.removeEventListener("storage",on);},[]);
  return {isAuthed,setAuthed}; }
