import type { Point, PointType } from "./types";

const API_BASE = (import.meta as any).env?.VITE_API_BASE?.toString().trim() || "";

export type GetPointsParams = {
  filter?: PointType;
  bbox?: [number, number, number, number]; // [minLng,minLat,maxLng,maxLat]
  limit?: number;
  q?: string;
};

export async function getPoints(params: GetPointsParams = {}): Promise<Point[]> {
  if (!API_BASE) throw new Error("VITE_API_BASE is not set");

  const u = new URL(`${API_BASE}/api/v1/map/points`);
  u.searchParams.set("limit", String(params.limit ?? 500));
  if (params.filter) u.searchParams.set("filter", params.filter);
  if (params.bbox) u.searchParams.set("bbox", params.bbox.join(","));
  if (params.q) u.searchParams.set("q", params.q);

  const res = await fetch(u.toString(), { headers: { Accept: "application/json" } });
  const ct = res.headers.get("content-type") || "";
  if (!res.ok || !ct.includes("application/json")) {
    throw new Error(`Bad API response: ${res.status}`);
  }

  const data = await res.json();
  const items: any[] = data?.items ?? data ?? [];
  return items.map((it: any, i: number) => {
    const tags: string[] | null =
      Array.isArray(it.tags) ? it.tags :
      typeof it.tags === "string" ? it.tags.split(",").map((s: string)=>s.trim()).filter(Boolean) :
      null;

    return {
      id: Number(it.id ?? i+1),
      title: String(it.title ?? `Point ${i+1}`),
      lat: Number(it.lat ?? it.latitude),
      lng: Number(it.lng ?? it.longitude),
      type: it.type ?? it.category ?? undefined,
      description: it.description ?? it.note ?? null,
      address: it.address ?? null,
      tags
    } as Point;
  });
}
