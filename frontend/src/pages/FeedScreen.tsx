import React, { useEffect, useState } from 'react';
import { feed, likeCatch, rateCatch, bonusAward } from '../api';
import Icon from '../components/Icon';
import config from '../config';
import { Link } from 'react-router-dom';
import RatingStars from '../components/RatingStars';
import BannerSlot from '../components/BannerSlot';
import { pushToast } from '../components/Toast';

const FeedScreen: React.FC = () => {
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    feed({limit:20, offset:0})
      .then((r)=> Array.isArray(r)? setItems(r) : setItems([]))
      .catch((e)=> setErr(e.message||'Ошибка загрузки ленты'));
  },[]);

  async function onLike(id:any){
    try{
      await likeCatch(id);
      pushToast('Лайк засчитан');
      // Попытка начислить бонус (если бэк поддерживает)
      bonusAward('like', {catch_id:id}).catch(()=>{});
    }catch(e:any){ pushToast(e?.message||'Ошибка'); }
  }
  async function onRate(id:any, stars:number){
    try{
      await rateCatch(id, stars);
      pushToast(`Оценка ${stars}/5 сохранена`);
      bonusAward('like', {kind:'rate', catch_id:id, stars}).catch(()=>{});
    }catch(e:any){ pushToast(e?.message||'Ошибка'); }
  }

  const spaced = [];
  const every = config.banners.feedEvery;
  for (let i=0;i<items.length;i++){
    spaced.push({kind:'post', data:items[i]});
    if ((i+1) % every === 0) spaced.push({kind:'banner', slot:`feed_${(i+1)/every}`});
  }

  return (
    <div className="container">
      <h2 className="h2">Лента</h2>
      {err && <div className="card glass" style={{color:'#ffb4b4'}}>{err}</div>}

      {(spaced.length? spaced : items.map(x=>({kind:'post', data:x}))).map((row:any, idx:number)=>{
        if (row.kind==='banner') return <BannerSlot key={`b-${idx}`} slot={row.slot} />;
        const it = row.data;
        return (
          <div key={it.id ?? idx} className="glass card">
            <div className="row" style={{justifyContent:'space-between'}}>
              <div className="row">
                <strong>{it.user_name || 'рыбак'}</strong>
                <span className="muted">· {new Date(it.created_at||Date.now()).toLocaleString()}</span>
              </div>
              <div className="row">
                <button className="btn" onClick={()=>onLike(it.id)}><Icon name={config.icons.like} /> {it.likes_count ?? 0}</button>
                <Link className="btn" to={`/catch/${it.id}`}><Icon name={config.icons.comment} /> {it.comments_count ?? 0}</Link>
                <button className="btn"><Icon name={config.icons.share} /> Поделиться</button>
              </div>
            </div>

            {it.media_url && <img src={it.media_url} alt="" style={{width:'100%', borderRadius:12, marginTop:8}} />}
            {it.caption && <div style={{marginTop:8}}>{it.caption}</div>}

            <div className="row" style={{marginTop:8, justifyContent:'space-between', alignItems:'center'}}>
              <div className="muted">Оцените улов</div>
              <RatingStars value={Math.round(it.rating_avg || 0)} onChange={(v)=>onRate(it.id, v)} />
            </div>
          </div>
        );
      })}
    </div>
  );
};
export default FeedScreen;
