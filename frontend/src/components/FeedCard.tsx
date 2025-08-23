import React from "react";
import type { FeedItem } from "../types/feed";

const fallbackAvatar = "data:image/svg+xml;utf8," + encodeURIComponent(
  `<svg xmlns='http://www.w3.org/2000/svg' width='64' height='64'>
     <rect width='100%' height='100%' rx='8' ry='8' fill='#e5e7eb'/>
     <text x='50%' y='54%' text-anchor='middle' font-size='28' fill='#9ca3af'>👤</text>
   </svg>`
);

export default function FeedCard({ item }: { item: FeedItem }) {
  const name = item.user_name || "Аноним";
  const avatar = item.user_avatar || fallbackAvatar;
  const when   = item.caught_at || item.created_at || null;

  return (
    <article className="rounded-2xl p-3 mb-3 bg-white/70 backdrop-blur border border-white/50 shadow-sm">
      <header className="flex items-center gap-3">
        <img
          src={avatar}
          alt={name}
          className="w-10 h-10 rounded-full object-cover border border-white/70"
          onError={(e)=> (e.currentTarget.src = fallbackAvatar)}
        />
        <div className="min-w-0">
          <div className="text-sm font-semibold text-gray-900 truncate">{name}</div>
          <div className="text-xs text-gray-500">
            {when ? new Date(when).toLocaleString() : ""}
            {item.place_title ? ` • ${item.place_title}` : ""}
          </div>
        </div>
      </header>

      {item.photo_url && (
        <div className="mt-3 overflow-hidden rounded-xl">
          <img src={item.photo_url} alt={item.species ?? "Улов"} className="w-full object-cover max-h-[360px]" />
        </div>
      )}

      <div className="mt-3">
        <div className="text-base font-medium text-gray-900">
          {item.species ?? (item.notes ? item.notes.slice(0,64) + (item.notes.length>64 ? "…" : "") : "Улов")}
        </div>
        <div className="text-sm text-gray-600 flex flex-wrap gap-x-4">
          {item.weight != null && <span>Вес: {item.weight}</span>}
          {item.length != null && <span>Длина: {item.length}</span>}
          {item.style && <span>Стиль: {item.style}</span>}
          {item.lure && <span>Приманка: {item.lure}</span>}
        </div>
      </div>

      <footer className="mt-3 flex items-center gap-4 text-sm text-gray-700">
        <button className="px-3 py-1 rounded-full bg-white/60 border border-white/60">❤ {item.likes_count ?? 0}</button>
        <button className="px-3 py-1 rounded-full bg-white/60 border border-white/60">💬 {item.comments_count ?? 0}</button>
      </footer>
    </article>
  );
}
