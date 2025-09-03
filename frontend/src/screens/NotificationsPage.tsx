import React, { useEffect, useState } from "react";
import Icon from "../components/Icon";

type Noti = {
  id: number;
  type: string; // "like" | "comment" | "follow" | "system"
  title: string;
  body?: string;
  created_at: string;
  is_read?: boolean;
  link?: string;
};

async function fetchNotifications(): Promise<Noti[]> {
  try {
    const base = (import.meta as any).env?.VITE_API_BASE || "https://api.fishtrackpro.ru/api/v1";
    const r = await fetch(`${base}/notifications`, { credentials: "include" });
    if (!r.ok) return [];
    const j = await r.json();
    return Array.isArray(j.items) ? j.items : [];
  } catch {
    return [];
  }
}

export default function NotificationsPage(){
  const [items, setItems] = useState<Noti[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(()=> {
    fetchNotifications().then((list)=> {
      setItems(list);
      setLoading(false);
    });
  },[]);

  if (loading) return <div className="p-4 text-gray-500">Загрузка…</div>;
  if (!items.length) return <div className="p-4 text-gray-500">Уведомлений пока нет</div>;

  const iconByType: Record<string,string> = {
    like: "like",
    comment: "comment",
    follow: "friends",
    system: "notifications",
  };

  return (
    <div className="pb-24">
      <div className="sticky top-0 z-header backdrop-blur bg-white/60 border-b border-white/30 p-3 flex items-center gap-2">
        <Icon name="alerts" />
        <div className="font-semibold">Уведомления</div>
      </div>

      <ul className="divide-y divide-gray-100">
        {items.map(n => (
          <li key={n.id} className="p-3 flex gap-3 items-start">
            <Icon name={iconByType[n.type] || "notifications"} className={`${n.is_read ? "text-gray-400" : "text-blue-600"}`} />
            <div className="flex-1">
              <div className="font-medium">{n.title}</div>
              {n.body && <div className="text-gray-600 text-sm">{n.body}</div>}
              <div className="text-xs text-gray-400 mt-1">{new Date(n.created_at).toLocaleString()}</div>
            </div>
            {n.link && (
              <a href={n.link} className="text-sm text-blue-600 hover:underline">Открыть</a>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}
