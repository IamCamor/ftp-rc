export const API_BASE = (import.meta as any).env?.VITE_API_BASE || "http://127.0.0.1:8000/api";

export async function getJson<T = any>(path: string, params?: Record<string, any>): Promise<T> {
  const url = new URL(API_BASE + path);
  if (params) for (const [k,v] of Object.entries(params)) url.searchParams.set(k, String(v));
  const r = await fetch(url.toString());
  if (!r.ok) throw new Error("API error: " + r.status);
  return r.json();
}

export async function postJson<T = any>(path: string, body: any): Promise<T> {
  const r = await fetch(API_BASE + path, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) });
  if (!r.ok) throw new Error("API error: " + r.status);
  return r.json();
}

export async function upload(path: string, file: File, fieldName = "file"): Promise<void> {
  const fd = new FormData();
  fd.append(fieldName, file);
  const r = await fetch(API_BASE + path, { method: "POST", body: fd });
  if (!r.ok) throw new Error("Upload error: " + r.status);
}
