import axios from "axios";
const API_BASE = import.meta.env.VITE_API_BASE || "/api";
export const api = axios.create({ baseURL: `${API_BASE}/v1`, timeout: 10000 });

export type MapPoint = { id:number; lat:number; lng:number; title:string; type:string; is_highlighted?:boolean };
export type CatchItem = { id:number; lat:number; lng:number; fish:string; weight?:number; length?:number; created_at?:string };
export type EventItem = { id:number; title:string; region?:string; starts_at?:string; description?:string };
export type Club = { id:number; name:string; description?:string; logo?:string };

export async function health(){ return (await api.get("/health")).data; }

export async function fetchMapPoints(params?:{bbox?:string;filter?:string}){
  const { data } = await api.get("/map/points",{ params }); return data.items ?? data;
}
export async function createPoint(payload:any){ return (await api.post("/map/points", payload)).data; }

export async function fetchFeedGlobal(){ const { data } = await api.get("/feed/global"); return data.items ?? []; }
export async function fetchFeedLocal(lat:number,lng:number){ const { data } = await api.get("/feed/local",{ params:{lat,lng} }); return data.items ?? []; }

export async function createCatch(payload:any){ return (await api.post("/catches", payload)).data; }

export async function fetchEvents(params?:any){ const { data } = await api.get("/events",{ params }); return data.items ?? []; }
export async function createEvent(payload:any){ return (await api.post("/events", payload)).data; }

export async function fetchClubs(){ const { data } = await api.get("/clubs"); return data.items ?? []; }
export async function createClub(payload:Partial<Club>){ return (await api.post("/clubs", payload)).data; }
