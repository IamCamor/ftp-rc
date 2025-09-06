import React, { useEffect, useState } from 'react';
import api from '../api';
import Icon from '../components/Icon';

type FeedItem = {
  id:number;
  user_name?:string;
  media_url?:string;
  caption?:string;
  likes_count?:number;
  comments_count?:number;
  created_at?:string;
};

export default function FeedScreen(){
  const [data,setData] = useState<FeedItem[]>([]);
  const [error,setError] = useState('');

  useEffect(()=>{
    (async()=>{
      try{
        setError('');
        const res:any = await api.feed({limit:10, offset:0});
        const list = Array.isArray(res?.items) ? res.items
                   : Array.isArray(res?.data) ? res.data
                   : Array.isArray(res) ? res : [];
        setData(list);
      }catch(e:any){
        setError(e?.message||'Ошибка ленты');
      }
    })();
  },[]);

  return (
    <div className="p-3" style={{paddingBottom:80}}>
      <div className="glass card mb-3" style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
        <strong>Лента</strong>
        <a className="btn" href="/add-catch"><Icon name="add_photo_alternate" />&nbsp;Добавить улов</a>
      </div>
      {!!error && <div className="card" style={{color:'#ff9b9b'}}>{error}</div>}
      {data.map((it)=>(
        <div key={it.id} className="card glass mb-3">
          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:8}}>
            <div style={{width:32,height:32,borderRadius:'50%',background:'rgba(255,255,255,0.1)'}} />
            <div style={{fontWeight:600}}>{it.user_name||'Рыбак'}</div>
            <div style={{marginLeft:'auto', opacity:.7, fontSize:12}}>{new Date(it.created_at||Date.now()).toLocaleString()}</div>
          </div>
          {it.media_url && <img src={it.media_url} alt="" style={{width:'100%',borderRadius:12,objectFit:'cover',maxHeight:420}} />}
          {it.caption && <div style={{marginTop:8}}>{it.caption}</div>}
          <div style={{display:'flex',gap:16,marginTop:8}}>
            <button className="btn"><Icon name="favorite" /> {it.likes_count ?? 0}</button>
            <button className="btn"><Icon name="mode_comment" /> {it.comments_count ?? 0}</button>
            <button className="btn"><Icon name="share" /> Поделиться</button>
          </div>
          <div style={{marginTop:8}}>
            <a href={`/catch/${it.id}`}><Icon name="open_in_new" /> Открыть</a>
          </div>
        </div>
      ))}
    </div>
  );
}
