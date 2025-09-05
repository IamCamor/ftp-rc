import React,{useEffect,useState} from 'react';
import { notifications } from '../api';

export default function NotificationsPage(){
  const [items,setItems]=useState<any[]>([]);
  useEffect(()=>{ notifications().then(setItems); },[]);
  return (
    <div className="container" style={{padding:'12px 16px 90px'}}>
      <h2>Уведомления</h2>
      <div className="grid" style={{marginTop:12}}>
        {items.map((n,i)=>(
          <div key={i} className="glass-card card">
            <div><b>{n.title||'—'}</b></div>
            <div className="small">{n.body||''}</div>
            <div className="small">{n.created_at ? new Date(n.created_at).toLocaleString() : ''}</div>
          </div>
        ))}
        {!items.length && <div className="small">Пока пусто</div>}
      </div>
    </div>
  );
}
