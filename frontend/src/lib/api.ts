export const API_BASE = (import.meta as any).env?.VITE_API_BASE ?? "https://api.fishtrackpro.ru";

const url = (p:string)=> new URL(p, API_BASE).toString();

export async function getJSON<T=any>(p:string, q?:Record<string, any>) {
  const u = new URL(url(p)); if(q) Object.entries(q).forEach(([k,v])=> (v!==undefined&&v!==null) && u.searchParams.set(k,String(v)));
  const r = await fetch(u.toString(),{headers:{'Accept':'application/json'}});
  if(!r.ok) throw new Error(`${r.status}`);
  return r.json() as Promise<T>;
}
export async function postJSON<T=any>(p:string, body:any){
  const r=await fetch(url(p),{method:'POST',headers:{'Content-Type':'application/json','Accept':'application/json'},body:JSON.stringify(body)});
  if(!r.ok) throw new Error(`${r.status}`);
  return r.json() as Promise<T>;
}
export async function uploadFile(file:File){
  const form=new FormData(); form.append('file',file);
  const r=await fetch(url('/api/v1/upload'),{method:'POST',body:form});
  if(!r.ok) throw new Error('UPLOAD');
  return r.json() as Promise<{ok:boolean,url:string,type:'image'|'video'}>;
}

// API wrappers
export const api = {
  points: (q:any)=> getJSON('/api/v1/map/points', q),
  pointCats: ()=> getJSON('/api/v1/points/categories'),
  addPoint: (body:any)=> postJSON('/api/v1/points', body),

  weather: (q:any)=> getJSON('/api/v1/weather', q),

  feed: (q:any)=> getJSON('/api/v1/feed', q),
  catchById: (id:number)=> getJSON(`/api/v1/catch/${id}`),
  addCatch: (body:any)=> postJSON('/api/v1/catches', body),
  catchMarkers: (q:any)=> getJSON('/api/v1/catches/markers', q),

  comment: (id:number, body:any)=> postJSON(`/api/v1/catch/${id}/comments`, body),
  like: (id:number, body:any)=> postJSON(`/api/v1/catch/${id}/like`, body),
  follow: (userId:number, body:any)=> postJSON(`/api/v1/follow/${userId}`, body),
};
