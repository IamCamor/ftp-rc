
const BASE = import.meta.env.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";

async function req(path:string, init?:RequestInit){
  const res = await fetch(`${BASE}${path}`, {
    credentials: "include",
    headers: { "Accept":"application/json", ...(init?.headers||{}) },
    ...init
  });
  if (res.status===204) return null;
  if (!res.ok) {
    const t = await res.text().catch(()=>res.statusText);
    throw new Error(`${res.status} ${t}`);
  }
  const ct = res.headers.get("content-type")||"";
  return ct.includes("application/json") ? res.json() : res.text();
}

export const api = {
  getJSON: (p:string) => req(p),
  postJSON: (p:string, data:any) => req(p, { method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify(data) }),
  delete: (p:string) => req(p, { method:"DELETE" }),
  uploadFiles: async (p:string, files:File[])=>{
    const fd = new FormData();
    files.forEach(f=>fd.append("files[]", f));
    return req(p, { method:"POST", body: fd });
  }
};
