import React, { useEffect, useState } from 'react';
import { api } from '../api';

type Notice = {
  id: number|string;
  type: string;
  title?: string;
  message?: string;
  created_at?: string;
  link?: string;
};

export default function NotificationsPage() {
  const [items, setItems] = useState<Notice[]>([]);
  const [error, setError] = useState('');

  useEffect(()=>{
    (async ()=>{
      try {
        setError('');
        const data: any = await api.notifications();
        const list = Array.isArray(data?.items) ? data.items
                   : Array.isArray(data?.data) ? data.data
                   : Array.isArray(data) ? data : [];
        setItems(list);
      } catch (e:any) {
        // Часто: 404 если ручка ещё не сделана на бэке, или CORS
        setError(e?.message || 'Недоступно');
        setItems([]);
      }
    })();
  },[]);

  return (
    <div className="p-3">
      <div className="glass card p-3 mb-3">
        <strong>Уведомления</strong>
      </div>

      {error && (
        <div className="text-sm text-amber-600 mb-3">
          {error.includes('404') ? 'Ручка /api/v1/notifications ещё не доступна' : error}
        </div>
      )}

      {items.length === 0 && !error && (
        <div className="opacity-70 text-sm">Пока уведомлений нет</div>
      )}

      <div className="grid gap-2">
        {items.map(n=>(
          <div key={String(n.id)} className="glass-light p-3">
            <div className="text-xs opacity-70">{n.type}</div>
            <div className="font-medium">{n.title || n.message || 'Событие'}</div>
            {n.link && (
              <a className="text-blue-600 underline" href={n.link}>Открыть</a>
            )}
            {n.created_at && (
              <div className="text-xs opacity-70 mt-1">{new Date(n.created_at).toLocaleString()}</div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
