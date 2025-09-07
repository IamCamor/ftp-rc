import React, { useEffect, useState } from 'react';
import { feed } from '../api';
import Icon from '../components/Icon';
import config from '../config';
import { Link } from 'react-router-dom';

const FeedScreen: React.FC = () => {
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    feed({limit:10, offset:0})
      .then((r)=> Array.isArray(r)? setItems(r) : setItems([]))
      .catch((e)=> setErr(e.message||'Ошибка загрузки ленты'));
  },[]);

  return (
    <div className="container">
      <h2 className="h2">Лента</h2>
      {err && <div className="card glass" style={{color:'#ffb4b4'}}>{err}</div>}

      {items.map((it, i)=>(
        <div key={i} className="glass card">
          <div className="row" style={{justifyContent:'space-between'}}>
            <div className="row">
              <strong>{it.user_name || 'рыбак'}</strong>
              <span className="muted">· {new Date(it.created_at||Date.now()).toLocaleString()}</span>
            </div>
            <div className="row">
              <button className="btn"><Icon name={config.icons.like} /> {it.likes_count ?? 0}</button>
              <Link className="btn" to={`/catch/${it.id}`}><Icon name={config.icons.comment} /> {it.comments_count ?? 0}</Link>
              <button className="btn"><Icon name={config.icons.share} /> Поделиться</button>
            </div>
          </div>
          {it.media_url && <img src={it.media_url} alt="" style={{width:'100%', borderRadius:12, marginTop:8}} />}
          {it.caption && <div style={{marginTop:8}}>{it.caption}</div>}
        </div>
      ))}
    </div>
  );
};
export default FeedScreen;
