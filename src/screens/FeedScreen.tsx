import { useEffect, useState } from 'react';
import { fetchFeed, CatchItem } from '../api/api';

export default function FeedScreen() {
  const [items, setItems] = useState<CatchItem[]>([]);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    (async () => {
      try {
        const data = await fetchFeed(10, 0);
        setItems(data);
      } catch (e:any) {
        console.error('feed error', e);
        setError('Не удалось загрузить ленту');
      }
    })();
  }, []);

  if (error) return <div className="p-4 text-red-600">{error}</div>;

  return (
    <div className="p-4 space-y-4">
      {items.map(it => (
        <article key={it.id} className="border rounded-xl p-4 shadow-sm">
          <header className="flex items-center gap-3">
            <img src={it.user_avatar || '/images/default-avatar.png'} className="w-10 h-10 rounded-full object-cover" />
            <div>
              <div className="font-semibold">{it.user_name}</div>
              <div className="text-xs text-gray-500">{new Date(it.created_at).toLocaleString()}</div>
            </div>
          </header>
          {it.media_url && (
            <div className="mt-3">
              <img src={it.media_url} className="w-full rounded-lg object-cover" />
            </div>
          )}
          <div className="mt-3 text-sm">
            {it.caption}
          </div>
          <footer className="mt-3 text-xs text-gray-500 flex gap-4">
            <span>👍 {it.likes_count}</span>
            <span>💬 {it.comments_count}</span>
            <span>🐟 {it.species || '—'}</span>
            <span>🔒 {it.privacy}</span>
          </footer>
        </article>
      ))}
    </div>
  );
}
