import React, {useEffect,useRef,useState} from 'react';
import { feed } from '../api';
import Icon from '../components/Icon';
import Avatar from '../components/Avatar';
import type { CatchItem } from '../types';

export default function FeedScreen(){
  const [items,setItems]=useState<CatchItem[]>([]);
  const [loading,setLoading]=useState(false);
  const [offset,setOffset]=useState(0);
  const ref = useRef<HTMLDivElement|null>(null);

  const load = async ()=>{
    if(loading) return;
    setLoading(true);
    try{
      const data = await feed(10, offset);
      setItems(prev => [...prev, ...data]);
      setOffset(prev => prev + data.length);
    } finally {
      setLoading(false);
    }
  };

  useEffect(()=>{ load(); },[]);
  useEffect(()=>{
    if(!ref.current) return;
    const io = new IntersectionObserver((e)=>{
      if(e[0].isIntersecting) load();
    }, {rootMargin:'400px'});
    io.observe(ref.current);
    return ()=>io.disconnect();
  },[ref.current]);

  const open = (id: number|string)=> window.navigate?.(`/catch/${id}`);

  return (
    <div className="container" style={{paddingBottom:90}}>
      <div className="grid" style={{marginTop:12}}>
        {items.map(it=>(
          <div key={String(it.id)} className="glass-card card">
            <div className="row" style={{justifyContent:'space-between'}}>
              <div className="row">
                <Avatar src={it.user_avatar}/>
                <div>
                  <div><b>{it.user_name||'Рыбак'}</b></div>
                  <div className="small">{new Date(it.created_at).toLocaleString()}</div>
                </div>
              </div>
              <Icon name="more" />
            </div>

            {it.media_url && (
              <div style={{margin:'12px -2px'}}>
                <img src={it.media_url} alt="" style={{width:'100%',borderRadius:12,border:'1px solid var(--stroke)'}} onClick={()=>open(it.id)}/>
              </div>
            )}

            <div className="row" style={{gap:12}}>
              <button className="badge" onClick={()=>open(it.id)}><Icon name="comment"/>{it.comments_count||0}</button>
              <span className="badge"><Icon name="like"/>{it.likes_count||0}</span>
              <a className="badge" onClick={()=>navigator.share?.({title:'Улов',url:location.origin+`/catch/${it.id}`})}><Icon name="share"/>Поделиться</a>
            </div>
          </div>
        ))}
        <div ref={ref} />
        {loading && <div className="small" style={{textAlign:'center',padding:20}}>Загрузка…</div>}
      </div>
    </div>
  );
}
