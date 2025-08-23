import React, { useEffect, useState } from "react";
import FeedCard from "../components/FeedCard";
import type { FeedItem } from "../types/feed";

const API = import.meta.env.VITE_API_BASE ?? "https://api.fishtrackpro.ru";

export default function FeedScreen() {
  const [items, setItems] = useState<FeedItem[]>([]);
  const [q, setQ] = useState("");
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    let abort = false;
    setLoading(true);
    setErr(null);

    const url = new URL("/api/v1/feed", API);
    url.searchParams.set("limit", "20");
    if (q.trim()) url.searchParams.set("q", q.trim());

    fetch(url.toString(), { credentials: "omit" })
      .then(async (r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json();
      })
      .then((json) => {
        if (!abort) setItems(Array.isArray(json.items) ? json.items : []);
      })
      .catch((e) => !abort && setErr(e.message))
      .finally(() => !abort && setLoading(false));

    return () => {
      abort = true;
    };
  }, [q]);

  return (
    <div className="px-3 pt-3 pb-20">
      <div className="sticky top-0 z-20 mb-3">
        <input
          className="w-full px-4 py-2 border rounded-full bg-white/60 backdrop-blur border-white/60"
          placeholder="Поиск по виду, приманке, заметкам…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </div>

      {loading && <div className="py-6 text-center text-gray-500">Загрузка…</div>}
      {err && <div className="py-6 text-center text-red-500">Ошибка: {err}</div>}

      {items.map((it) => (
        <FeedCard key={it.id} item={it} />
      ))}

      {!loading && !err && items.length === 0 && (
        <div className="py-6 text-center text-gray-500">Публикаций пока нет</div>
      )}
    </div>
  );
}