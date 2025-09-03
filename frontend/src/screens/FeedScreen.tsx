// src/screens/FeedScreen.tsx
import React, { useEffect, useRef, useState } from "react";
import HeaderBar from "../components/HeaderBar";
import { api } from "../api";

type FeedItem = {
  id: number;
  user_name?: string;
  user_avatar?: string;
  species?: string;
  media_url?: string;
  caption?: string;
  created_at?: string;
  likes_count?: number;
  comments_count?: number;
};

export default function FeedScreen() {
  const [items, setItems] = useState<FeedItem[]>([]);
  const [offset, setOffset] = useState(0);
  const [loading, setLoading] = useState(false);
  const anchor = useRef<HTMLDivElement>(null);

  const load = async () => {
    if (loading) return;
    setLoading(true);
    try {
      const rsp = await api.feed({ limit: 10, offset });
      setItems((x) => [...x, ...(rsp.items || [])]);
      setOffset((o) => (rsp.nextOffset ?? o + (rsp.items?.length || 0)));
    } catch (e) {
      console.warn("feed error", e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const io = new IntersectionObserver(
      (entries) => {
        if (entries.some((e) => e.isIntersecting)) load();
      },
      { rootMargin: "400px" }
    );
    if (anchor.current) io.observe(anchor.current);
    return () => io.disconnect();
  }, [anchor.current]); // eslint-disable-line

  return (
    <div className="w-full h-full pb-20">
      <HeaderBar title="Лента" onWeather={() => (window.location.hash = "#/weather")} onProfile={() => (window.location.hash = "#/profile")} />

      <div className="mx-auto max-w-md px-3 mt-16 space-y-4">
        {items.map((p) => (
          <article key={p.id} className="glass p-3">
            <div className="flex items-center gap-2">
              <img src={p.user_avatar || "/avatar.png"} className="w-8 h-8 rounded-full object-cover" />
              <div className="text-sm font-medium">{p.user_name || "Рыбак"}</div>
              <div className="ml-auto text-xs text-gray-500">{new Date(p.created_at || Date.now()).toLocaleString()}</div>
            </div>
            {p.media_url && (
              <div className="mt-2 overflow-hidden rounded-xl">
                {/* eslint-disable-next-line jsx-a11y/alt-text */}
                <img src={p.media_url} className="w-full h-64 object-cover" />
              </div>
            )}
            <div className="mt-2 text-sm text-gray-700">{p.caption}</div>
            <div className="mt-2 flex items-center gap-3 text-sm text-gray-600">
              <button onClick={() => api.likeCatch(p.id)} className="hover:text-pink-500">❤ {p.likes_count ?? 0}</button>
              <button onClick={() => (window.location.hash = `#/catch/${p.id}`)}>💬 {p.comments_count ?? 0}</button>
              <button onClick={() => navigator.share?.({ url: location.href })}>↗︎ Поделиться</button>
            </div>
          </article>
        ))}

        <div ref={anchor} className="h-10" />
        {loading && <div className="text-center text-gray-500 pb-8">Загрузка…</div>}
      </div>
    </div>
  );
}
