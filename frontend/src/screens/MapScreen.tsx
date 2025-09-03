// src/screens/MapScreen.tsx
import React, { useEffect, useMemo, useRef, useState } from "react";
import HeaderBar from "../components/HeaderBar";
import FilterChips from "../components/FilterChips";
import { api, BBox } from "../api";

type Point = {
  id: number;
  lat: number;
  lng: number;
  title: string;
  category?: string;
};

export default function MapScreen() {
  const [filter, setFilter] = useState<string>("all");
  const [items, setItems] = useState<Point[]>([]);
  const mapRef = useRef<HTMLDivElement>(null);

  const bboxFromMap = (): BBox | null => {
    // Simple fallback bbox around Moscow if map lib isn't mounted
    return [37.2, 55.5, 37.9, 55.95];
  };

  const load = async () => {
    const bbox = bboxFromMap();
    const p: any = { limit: 500 };
    if (filter !== "all") p.filter = filter;
    if (bbox) p.bbox = bbox;
    const rsp = await api.points(p);
    setItems(rsp.items || []);
  };

  useEffect(() => {
    load().catch(console.warn);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filter]);

  return (
    <div className="w-full h-full">
      <HeaderBar title="FishTrack" onWeather={() => (window.location.hash = "#/weather")} onProfile={() => (window.location.hash = "#/profile")} />

      <FilterChips active={filter} onChange={setFilter} />

      <div className="mx-auto max-w-md px-3 mt-3">
        <div ref={mapRef} className="w-full h-[70vh] rounded-2xl overflow-hidden relative ring-1 ring-white/60 bg-gradient-to-br from-sky-50 to-violet-50">
          {/* Lightweight canvas map placeholder to avoid external lib issues.
              If Leaflet/Maplibre is present, you can replace this block. */}
          <div className="absolute inset-0 flex items-center justify-center text-gray-500">
            Карта (замените на реальную, если подключена)
          </div>

          {/* markers */}
          <div className="absolute inset-0 pointer-events-none">
            {items.slice(0, 60).map((p) => (
              <div key={p.id} className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
                <div className="w-3 h-3 bg-pink-500 rounded-full shadow" title={p.title} />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
