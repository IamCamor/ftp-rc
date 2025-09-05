import React,{useEffect,useState} from 'react';
import { catchById } from '../api';
import Icon from '../components/Icon';
import Avatar from '../components/Avatar';
import type { CatchItem } from '../types';

export default function CatchDetailPage({id}:{id:string}){
  const [item,setItem]=useState<CatchItem|null>(null);
  useEffect(()=>{
    catchById(id).then(setItem).catch(()=>setItem(null));
  },[id]);
  if(!item) return <div className="container" style={{padding:20}}>Загрузка…</div>;

  const goPlace = ()=> item.place_id && window.navigate?.(`/place/${item.place_id}`);

  return (
    <div className="container" style={{paddingBottom:90}}>
      <div className="glass card" style={{marginTop:12}}>
        <div className="row" style={{justifyContent:'space-between'}}>
          <div className="row">
            <Avatar src={item.user_avatar}/>
            <div>
              <div><b>{item.user_name}</b></div>
              <div className="small">{new Date(item.created_at).toLocaleString()}</div>
            </div>
          </div>
          <Icon name="more"/>
        </div>

        {item.media_url && <img src={item.media_url} alt="" style={{width:'100%',borderRadius:12,marginTop:12,border:'1px solid var(--stroke)'}}/>}

        <div className="grid" style={{marginTop:12}}>
          <div className="row"><b>Вид:</b>&nbsp;{item.species||'—'}</div>
          <div className="row"><b>Метод:</b>&nbsp;{item.method||'—'}</div>
          <div className="row"><b>Приманка:</b>&nbsp;{item.bait||'—'}</div>
          <div className="row"><b>Снасть:</b>&nbsp;{item.gear||'—'}</div>
          {item.caption && <div className="row">{item.caption}</div>}
          {item.place_id && <a className="badge" onClick={goPlace} style={{cursor:'pointer'}}><Icon name="map"/> К месту</a>}
        </div>
      </div>
    </div>
  );
}
