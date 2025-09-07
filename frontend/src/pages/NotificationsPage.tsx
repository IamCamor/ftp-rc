import React, { useEffect, useState } from 'react';
import config from '../config';

type Notice = {
  id: number | string;
  type: string;
  title?: string;
  message?: string;
  created_at?: string;
  read_at?: string | null;
};

const NotificationsPage: React.FC = () => {
  const [items, setItems] = useState<Notice[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let alive = true;

    async function load() {
      setLoading(true);
      setError(null);

      try {
        const token = localStorage.getItem('token') || '';
        const res = await fetch(`${config.apiBase}/notifications`, {
          headers: {
            'Accept': 'application/json',
            ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
          },
          credentials: 'include',
        });

        // Бек может вернуть 404, если роут ещё не включён
        if (!res.ok) {
          const text = await res.text().catch(() => '');
          throw new Error(`HTTP ${res.status}: ${text || res.statusText}`);
        }

        const data = await res.json();
        // Ожидаем массив; если пришёл объект — аккуратно достанем поле
        const list: Notice[] = Array.isArray(data)
          ? data
          : Array.isArray((data as any).data)
          ? (data as any).data
          : [];

        if (!alive) return;
        setItems(list);
      } catch (e: any) {
        if (!alive) return;
        // Частый кейс — CORS/сеть
        setError(
          e?.message?.includes('Failed to fetch')
            ? 'Не удалось загрузить. Проверьте сеть или CORS.'
            : e?.message || 'Ошибка загрузки уведомлений'
        );
      } finally {
        if (alive) setLoading(false);
      }
    }

    load();
    return () => {
      alive = false;
    };
  }, []);

  if (loading) {
    return <div className="container">Загрузка уведомлений…</div>;
  }

  if (error) {
    return (
      <div className="container">
        <div className="card error">
          <div className="card-title">Ошибка</div>
          <div className="card-text">{error}</div>
        </div>
      </div>
    );
  }

  if (!items || items.length === 0) {
    return <div className="container">Пока уведомлений нет.</div>;
  }

  return (
    <div className="container">
      <h1 className="page-title">Уведомления</h1>
      <ul className="list">
        {items.map((n) => (
          <li key={n.id} className="list-item">
            <div className="list-title">{n.title || n.type}</div>
            {n.message && <div className="list-subtitle">{n.message}</div>}
            <div className="list-meta">
              {n.created_at ? new Date(n.created_at).toLocaleString() : ''}
              {n.read_at ? ' • прочитано' : ''}
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
};

export default NotificationsPage;
