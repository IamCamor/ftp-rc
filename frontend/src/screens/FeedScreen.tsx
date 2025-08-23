import React, { useEffect, useRef, useState } from "react";
import FeedTabs from "../components/FeedTabs";
import FeedCard from "../components/FeedCard";
import type { FeedItem } from "../types/feed";
import { buildUrl } from "../lib/api";

type Tab = "global"|"local"|"follow";

export default function FeedScreen() {
  const [tab, setTab] = useState<Tab>("global");
  const [q, setQ] = useState("");
  const [items, setItems] = useState<FeedItem[]>([]);
  const [offset, setOffset] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const sentinelRef = useRef<HTMLDivElement | null>(null);
  const geoRef = useRef<{lat:number, lng:number} | null>(null);

  // reset on tab/q change
  useEffect(() => {
    setItems([]); setOffset(0); setHasMore(true); setErr(null);
  }, [tab, q]);

  // local tab: get geolocation once
  useEffect(() => {
    if (tab !== "local") return;
    if (geoRef.current) return;
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => { geoRef.current = { lat: pos.coords.latitude, lng: pos.coords.longitude }; },
      () => { geoRef.current = null; },
      { enableHighAccuracy: true, timeout: 5000 }
    );
  }, [tab]);

  // loader
  useEffect(() => {
    if (!hasMore || loading) return;
    const el = sentinelRef.current;
    if (!el) return;
    const io = new IntersectionObserver((entries)=>{
      entries.forEach((e)=>{
        if (e.isIntersecting) fetchMore();
      });
    }, { rootMargin: "300px" });
    io.observe(el);
    return () => io.disconnect();
  }, [hasMore, loading, sentinelRef.current, tab, q]);

  const fetchMore = () => {
    if (!hasMore || loading) return;
    setLoading(true); setErr(null);

    const params: Record<string, any> = { limit: 20, offset, tab, q: q.trim() };
    if (tab === "local" && geoRef.current) {
      params.lat = geoRef.current.lat;
      params.lng = geoRef.current.lng;
      params.radius_km = 50;
    }

    fetch(buildUrl("/api/v1/feed", params), { mode: "cors" })
      .then(async r => { if (!r.ok) throw new Error(`HTTP ${r.status}`); return r.json(); })
      .then(json => {
        const arr: FeedItem[] = Array.isArray(json.items) ? json.items : [];
        setItems(prev => prev.concat(arr));
        if (json.next != null) setOffset(json.next); else setHasMore(false);
      })
      .catch(e => setErr(e.message))
      .finally(()=> setLoading(false));
  };

  return (
    <div className="px-3 pt-3 pb-24">
      <FeedTabs active={tab} onChange={setTab}/>
      <div className="mt-3 sticky top-[56px] z-10">
        <input
          className="w-full rounded-full px-4 py-2 bg-white/60 backdrop-blur border border-white/60"
          placeholder="Поиск по виду, приманке, снастям, заметкам…"
          value={q}
          onChange={(e)=>setQ(e.target.value)}
        />
      </div>

      <div className="mt-3">
        {items.map(it => <FeedCard key={it.id} item={it} />)}
      </div>

      {err && <div className="text-center text-red-500 py-4">Ошибка: {err}</div>}
      {loading && <div className="text-center text-gray-500 py-4">Загрузка…</div>}
      {!loading && !err && items.length===0 && !hasMore && (
        <div className="text-center text-gray-500 py-6">Публикаций пока нет</div>
      )}

      <div ref={sentinelRef} className="h-6" />
    </div>
  );
}
