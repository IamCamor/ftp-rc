import React from "react";
import type { FeedItem } from "../types/feed";

const fallbackAvatar =
  "data:image/svg+xml;utf8," +
  encodeURIComponent(
    `<svg xmlns='http://www.w3.org/2000/svg' width='64' height='64'>
      <rect width='100%' height='100%' rx='8' ry='8' fill='#e5e7eb'/>
      <text x='50%' y='54%' text-anchor='middle' font-size='28' fill='#9ca3af'>👤</text>
    </svg>`
  );

export default function FeedCard({ item }: { item: FeedItem }) {
  const name = item.user_name || "Аноним";
  const avatar = item.user_avatar || fallbackAvatar;
  const title =
    item.species ??
    (item.notes ? item.notes.slice(0, 48) + (item.notes.length > 48 ? "…" : "") : "Улов");

  return (
    <article className="p-3 mb-3 border shadow-sm rounded-2xl bg-white/70 backdrop-blur border-white/50">
      <header className="flex items-center gap-3">
        <img
          src={avatar}
          alt={name}
          className="object-cover w-10 h-10 border rounded-full border-white/70"
          onError={(e) => ((e.currentTarget.src = fallbackAvatar))}
        />
        <div className="min-w-0">
          <div className="text-sm font-semibold text-gray-900 truncate">{name}</div>
          <div className="text-xs text-gray-500">
            {item.caught_at ? new Date(item.caught_at).toLocaleString() :
             item.created_at ? new Date(item.created_at).toLocaleString() : ""}
          </div>
        </div>
      </header>

      {item.photo_url && (
        <div className="mt-3 overflow-hidden rounded-xl">
          <img src={item.photo_url} alt={title} className="w-full object-cover max-h-[360px]" />
        </div>
      )}

      <div className="mt-3">
        <div className="text-base font-medium text-gray-900">{title}</div>
        <div className="text-sm text-gray-600">
          {item.species && <span className="mr-3">Вид: {item.species}</span>}
          {item.weight != null && <span className="mr-3">Вес: {item.weight} кг</span>}
          {item.length != null && <span>Длина: {item.length} см</span>}
        </div>
      </div>

      <footer className="flex items-center gap-4 mt-3 text-sm text-gray-600">
        <button className="px-3 py-1 border rounded-full bg-white/60 border-white/60">
          ❤ {item.likes_count ?? 0}
        </button>
        <button className="px-3 py-1 border rounded-full bg-white/60 border-white/60">
          💬 {item.comments_count ?? 0}
        </button>
      </footer>
    </article>
  );
}