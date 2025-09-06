import React, { useEffect, useState } from 'react';
import { notifications } from '../api';

const NotificationsPage:React.FC = () => {
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState('');
  useEffect(() => {
    (async () => {
      try { setItems(await notifications()); } catch (e:any) { setErr(e?.message || 'Ошибка'); }
    })();
  }, []);
  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Уведомления</h2>
        {err && <div className="subtle">{err}</div>}
        {!items.length && !err && <div className="subtle">Пока нет уведомлений</div>}
        <ul>
          {items.map((n:any, i:number) => <li key={i}>{n.title || n.text || 'Уведомление'}</li>)}
        </ul>
      </div>
    </div>
  );
};
export default NotificationsPage;
