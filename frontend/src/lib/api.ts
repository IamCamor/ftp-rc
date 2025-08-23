export const API_BASE = (import.meta as any).env?.VITE_API_BASE ?? "https://api.fishtrackpro.ru";

export function buildUrl(path: string, params?: Record<string, any>) {
  const u = new URL(path, API_BASE);
  if (params) {
    Object.entries(params).forEach(([k,v]) => {
      if (v !== undefined && v !== null && v !== '') u.searchParams.set(k, String(v));
    });
  }
  return u.toString();
}
