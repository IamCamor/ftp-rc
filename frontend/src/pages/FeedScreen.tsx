import React, { useEffect, useState } from 'react';
import { feed } from '../api';
import { Link } from 'react-router-dom';

const FeedScreen:React.FC = () => {
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState<string>('');

  useEffect(() => {
    (async () => {
      try {
        const data = await feed(10,0);
        setItems(Array.isArray(data)?data:[]);
      } catch (e:any) {
        setErr(e?.message || 'Ошибка загрузки');
      }
    })();
  }, []);

  return (
    <div className="list">
      {err && <div className="glass card">{err}</div>}
      {items.map((it:any) => (
        <Link to={(it.type==='catch'?`/catch/${it.id}`:`/place/${it.id}`)} key={`f-${it.id}`} className="glass item">
          <img className="thumb" src={it.photo_url || (it.media && it.media[0]) || ''} alt="" />
          <div className="meta">
            <div className="title">{it.title || it.species || 'Публикация'}</div>
            <div className="subtle">{new Date(it.created_at || Date.now()).toLocaleString()}</div>
          </div>
        </Link>
      ))}
      {!items.length && !err && <div className="glass card">Пока пусто.</div>}
    </div>
  );
};
export default FeedScreen;
