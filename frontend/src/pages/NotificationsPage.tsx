import React, { useEffect, useState } from 'react';
import AppShell from '../components/AppShell';
import Icon from '../components/Icon';
import config from '../config';
import { notifications } from '../api';

type Notice = { id: string|number; title?: string; text?: string; created_at?: string };

export default function NotificationsPage(){
  const [items,setItems] = useState<Notice[]>([]);
  const [err,setErr] = useState<string| null>(null);
  const enabled = config.flags.notificationsEnabled;

  useEffect(()=>{
    let aborted = false;
    (async()=>{
      setErr(null);
      if (!enabled){ setItems([]); return; }
      try{
        const data = await notifications();
        if (!aborted) setItems(Array.isArray(data)? data : (data?.items ?? []));
      }catch(e:any){
        // если 404 — просто показываем пусто и подсказку
        setErr(e?.message ?? 'Ошибка загрузки');
      }
    })();
    return ()=>{ aborted = true; };
  },[enabled]);

  return (
    <AppShell>
      <div className="glass card" style={{display:'grid', gap:12}}>
        <div className="row"><Icon name="notifications" /><b>Уведомления</b></div>
        {!enabled && <div className="help">Функция пока не активирована (ожидаем роут /api/v1/notifications).</div>}
        {enabled && err && <div className="help">Не удалось загрузить уведомления: {err}</div>}
        {enabled && !err && items.length===0 && <div className="help">Уведомлений пока нет.</div>}
        {enabled && items.map(n=>(
          <div key={String(n.id)} className="glass card" style={{padding:10}}>
            <div className="row" style={{justifyContent:'space-between'}}>
              <b>{n.title ?? 'Уведомление'}</b>
              {n.created_at && <span className="help">{new Date(n.created_at).toLocaleString()}</span>}
            </div>
            {n.text && <div style={{marginTop:6}}>{n.text}</div>}
          </div>
        ))}
      </div>
    </AppShell>
  );
}
