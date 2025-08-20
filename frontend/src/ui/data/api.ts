import axios from "axios";
const API_BASE = import.meta.env.VITE_API_BASE || "/api";
export const api = axios.create({ baseURL: `${API_BASE}/v1`, timeout: 10000 });

export type CatchItem = { id:number; lat:number; lng:number; fish:string; weight?:number; length?:number; user?:{id:number;name:string}; created_at?:string; };
export type MapPoint = { id:number; lat:number; lng:number; title:string; type:"shop"|"slip"|"camp"|"catch"|"spot"; is_highlighted?:boolean; };

export async function fetchFeed(tab:"global"|"local"|"follow", coords?:{lat:number;lng:number}){
  const url = tab==="global" ? "/feed/global" : tab==="follow" ? "/feed/follow" : "/feed/local";
  const params = tab==="local" ? coords : undefined;
  const { data } = await api.get(url, { params }); return data.items ?? data;
}
export async function fetchMapPoints(params:{bbox?:string;filter?:string}){
  const { data } = await api.get("/map/points", { params }); return data.items ?? data;
}
export async function createCatch(payload:any){ return (await api.post("/catches", payload)).data; }
export async function createEvent(payload:any){ return (await api.post("/events", payload)).data; }
export async function createPoint(payload:any){ return (await api.post("/map/points", payload)).data; }
export async function health(){ return (await api.get("/health")).data; }
