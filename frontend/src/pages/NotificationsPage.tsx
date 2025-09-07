import React, { useEffect, useState } from 'react';
import { notifications } from '../api';

const NotificationsPage: React.FC = () => {
  const [list, setList] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    notifications()
      .then(r => setList(Array.isArray(r)? r: []))
      .catch(e => setErr(e.message || 'Маршрут уведомлений не найден'));
  },[]);

  return (
    <div className="container">
      <h2 className="h2">Уведомления</h2>
      {err && <div className="card glass" style={{color:'#ffb4b4'}}>{err}</div>}
      {!err && list.length===0 && <div className="card glass">Пока пусто</div>}
      <div className="grid">
        {list.map((n,i)=>(
          <div key={i} className="card glass">
            <div style={{fontWeight:600}}>{n.title || 'Уведомление'}</div>
            <div className="muted">{n.created_at ? new Date(n.created_at).toLocaleString(): ''}</div>
            <div style={{marginTop:6}}>{n.text || n.message || ''}</div>
          </div>
        ))}
      </div>
    </div>
  );
};
export default NotificationsPage;
