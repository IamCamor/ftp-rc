import type { Point, PointType } from "./types";
import { authHeader } from "./auth";

const API_BASE = (import.meta as any).env?.VITE_API_BASE?.toString().trim() || "";

export type GetPointsParams={ filter?:PointType; bbox?:[number,number,number,number]; limit?:number; q?:string; };
export async function getPoints(params:GetPointsParams={}):Promise<Point[]>{
  if(!API_BASE) throw new Error("VITE_API_BASE is not set");
  const u=new URL(`${API_BASE}/api/v1/map/points`);
  u.searchParams.set("limit", String(params.limit ?? 500));
  if(params.filter) u.searchParams.set("filter", params.filter);
  if(params.bbox) u.searchParams.set("bbox", params.bbox.join(","));
  if(params.q) u.searchParams.set("q", params.q);
  const res=await fetch(u.toString(),{headers:{Accept:"application/json"}});
  const ct=res.headers.get("content-type")||"";
  if(!res.ok || !ct.includes("application/json")) throw new Error(`Bad API response: ${res.status}`);
  const data=await res.json(); const items:any[]=data?.items ?? data ?? [];
  return items.map((it:any,i:number)=>({
    id:Number(it.id ?? i+1),
    title:String(it.title ?? `Point ${i+1}`),
    lat:Number(it.lat ?? it.latitude), lng:Number(it.lng ?? it.longitude),
    type: it.type ?? it.category ?? undefined,
    description: it.description ?? it.note ?? null,
    address: it.address ?? null,
    tags: Array.isArray(it.tags)?it.tags: (typeof it.tags==="string"? it.tags.split(",").map((s:string)=>s.trim()).filter(Boolean): null)
  }));
}

// AUTH
export async function login(body:{email:string;password:string;}):Promise<{token:string}>{
  const res=await fetch(`${API_BASE}/api/v1/login`,{method:"POST",headers:{"Content-Type":"application/json",Accept:"application/json"},body:JSON.stringify(body)});
  if(!res.ok) throw new Error("Неверный email или пароль"); return res.json();
}
export async function registerUser(body:{email:string;password:string;name:string;}):Promise<{token:string}>{
  const res=await fetch(`${API_BASE}/api/v1/register`,{method:"POST",headers:{"Content-Type":"application/json",Accept:"application/json"},body:JSON.stringify(body)});
  if(!res.ok) throw new Error("Не удалось зарегистрироваться"); return res.json();
}
export async function getMe(){
  const res=await fetch(`${API_BASE}/api/v1/me`,{headers:{Accept:"application/json",...authHeader()}});
  if(!res.ok) throw new Error("Не авторизованы"); return res.json();
}
export async function logout(){ await fetch(`${API_BASE}/api/v1/logout`,{method:"POST",headers:{...authHeader()}}); }

// FEED
export async function fetchFeed(params:{q?:string;limit?:number}={}){
  const u=new URL(`${API_BASE}/api/v1/feed`); if(params.q) u.searchParams.set("q",params.q); if(params.limit) u.searchParams.set("limit",String(params.limit));
  const res=await fetch(u.toString(),{headers:{Accept:"application/json",...authHeader()}});
  if(!res.ok) throw new Error("Ошибка загрузки ленты"); return res.json();
}
export async function likePost(id:number){
  const res=await fetch(`${API_BASE}/api/v1/feed/${id}/like`,{method:"POST",headers:{Accept:"application/json",...authHeader()}});
  if(!res.ok) throw new Error("Не удалось поставить лайк"); return res.json();
}

export async function checkHandleAvailability(handle:string){ const API_BASE=(import.meta as any).env?.VITE_API_BASE?.toString().trim()||""; const r=await fetch(`${API_BASE}/api/v1/profile/handle-available?handle=${encodeURIComponent(handle)}`,{headers:{Accept:"application/json"}}); if(!r.ok) throw new Error("Ошибка проверки"); const j=await r.json(); return !!j?.available; }

export async function completeProfile(payload: FormData){ const API_BASE=(import.meta as any).env?.VITE_API_BASE?.toString().trim()||""; const r=await fetch(`${API_BASE}/api/v1/profile/setup`,{ method:"POST", body: payload }); if(!r.ok) throw new Error("Не удалось сохранить профиль"); return r.json(); }

export async function uploadAvatar(file: File){ const API_BASE=(import.meta as any).env?.VITE_API_BASE?.toString().trim()||""; const fd=new FormData(); fd.append("avatar", file); const r=await fetch(`${API_BASE}/api/v1/profile/avatar`,{ method:"POST", body: fd }); if(!r.ok) throw new Error("Не удалось загрузить аватар"); return r.json(); }
