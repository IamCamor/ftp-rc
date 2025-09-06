import React, { useEffect, useState } from 'react';
import api from '../api';

type N = { id:number|string; type:string; text:string; created_at?:string };

export default function NotificationsPage(){
  const [list,setList] = useState<N[]>([]);
  const [error,setError] = useState('');

  useEffect(()=>{
    (async()=>{
      try{
        setError('');
        const res:any = await api.notifications();
        const arr = Array.isArray(res?.items)?res.items : Array.isArray(res?.data)?res.data : Array.isArray(res)?res : [];
        setList(arr);
      }catch(e:any){
        setError(e?.message||'Не удалось загрузить уведомления');
      }
    })();
  },[]);

  return (
    <div className="p-3" style={{paddingBottom:80}}>
      <div className="glass card mb-3"><strong>Уведомления</strong></div>
      {!!error && <div className="card" style={{color:'#ff9b9b'}}>{error}</div>}
      {list.length===0 && !error && <div className="card">Уведомлений пока нет</div>}
      {list.map(n=>(
        <div key={String(n.id)} className="card glass mb-2">
          <div style={{fontWeight:600, marginBottom:4}}>{n.type}</div>
          <div>{n.text}</div>
          <div style={{opacity:.6, fontSize:12, marginTop:6}}>{n.created_at? new Date(n.created_at).toLocaleString() : ''}</div>
        </div>
      ))}
    </div>
  );
}
