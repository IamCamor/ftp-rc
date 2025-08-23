export const API_BASE = (import.meta as any).env?.VITE_API_BASE ?? "https://api.fishtrackpro.ru";
export const buildUrl = (path: string) => new URL(path, API_BASE).toString();
export async function apiGet<T=any>(path: string, q?: Record<string, string|number|boolean|null|undefined>) {
  const url = new URL(buildUrl(path));
  if (q) Object.entries(q).forEach(([k,v]) => (v!==undefined && v!==null) && url.searchParams.set(k, String(v)));
  const r = await fetch(url.toString(), { headers: { 'Accept':'application/json' }});
  if (!r.ok) throw new Error(`GET ${url} -> ${r.status}`);
  return r.json() as Promise<T>;
}
export async function apiPostJSON<T=any>(path: string, body: any) {
  const r = await fetch(buildUrl(path), { method:'POST', headers:{ 'Content-Type':'application/json', 'Accept':'application/json' }, body: JSON.stringify(body) });
  if (!r.ok) throw new Error(`POST ${path} -> ${r.status}`);
  return r.json() as Promise<T>;
}
export async function apiUpload(file: File) {
  const form = new FormData(); form.append('file', file);
  const r = await fetch(buildUrl('/api/v1/upload'), { method:'POST', body: form });
  if (!r.ok) throw new Error(`UPLOAD -> ${r.status}`);
  return r.json() as Promise<{ok:boolean,url:string,type:'image'|'video'}>;
}
