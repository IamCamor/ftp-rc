import axios from "axios";
const API_BASE = import.meta.env.VITE_API_BASE || "/api";
export const api = axios.create({ baseURL: `${API_BASE}/v1`, timeout: 15000 });

export type Media = { id:number; url:string; type?:string; size?:number };
export type MapPoint = { id:number; lat:number; lng:number; title:string; type:"shop"|"slip"|"camp"|"catch"|"spot"; is_highlighted?:boolean; photo?:Media };
export type CatchItem = { id:number; lat:number; lng:number; fish:string; weight?:number; length?:number; style?:string; privacy?:string; created_at?:string; photo?:Media };

export async function health(){ return (await api.get("/health")).data; }
export async function uploadImage(file:File){
  const fd = new FormData(); fd.append("file", file);
  return (await api.post("/upload/image", fd, { headers:{ 'Content-Type':'multipart/form-data' } })).data as Media;
}

export async function fetchMapPoints(params?:{bbox?:string;filter?:string}){
  const { data } = await api.get("/map/points",{ params }); return data.items ?? data;
}
export async function createPoint(payload:Partial<MapPoint>){
  const { data } = await api.post("/map/points", payload); return data as MapPoint;
}

export async function fetchFeedGlobal(){ const { data } = await api.get("/catches"); return data.items ?? []; }
export async function createCatch(payload:Partial<CatchItem>){ const { data } = await api.post("/catches", payload); return data as CatchItem; }
