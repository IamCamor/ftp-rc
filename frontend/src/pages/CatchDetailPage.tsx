import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { catchById, addCatchComment } from '../api';
import Icon from '../components/Icon';
import config from '../config';

const CatchDetailPage: React.FC = () => {
  const { id } = useParams();
  const [data, setData] = useState<any>(null);
  const [err, setErr] = useState('');
  const [text, setText] = useState('');

  useEffect(()=>{
    if (!id) return;
    catchById(id).then(setData).catch((e)=> setErr(e.message||'Ошибка'));
  },[id]);

  async function submitComment(e:React.FormEvent){
    e.preventDefault();
    try{
      await addCatchComment(String(id), text);
      setText('');
      // простая перезагрузка данных
      const d = await catchById(String(id));
      setData(d);
    }catch(ex:any){
      alert(ex?.message||'Не удалось добавить комментарий');
    }
  }

  if (err) return <div className="container"><div className="card glass" style={{color:'#ffb4b4'}}>{err}</div></div>;
  if (!data) return <div className="container"><div className="card glass">Загрузка…</div></div>;

  return (
    <div className="container">
      <h2 className="h2">Улов #{id}</h2>
      {data.photo_url && <img src={data.photo_url} alt="" style={{width:'100%', borderRadius:12}} />}
      {data.caption && <div style={{marginTop:8}}>{data.caption}</div>}

      <div className="row" style={{gap:8, marginTop:10}}>
        <button className="btn"><Icon name={config.icons.like} /> {data.likes_count ?? 0}</button>
        <button className="btn"><Icon name={config.icons.share} /> Поделиться</button>
      </div>

      <h3 style={{marginTop:16}}>Комментарии</h3>
      <div className="grid">
        {(data.comments || []).map((c:any, i:number)=>(
          <div key={i} className="card glass">
            <div className="row" style={{justifyContent:'space-between'}}>
              <strong>{c.user_name || 'гость'}</strong>
              <span className="muted">{new Date(c.created_at||Date.now()).toLocaleString()}</span>
            </div>
            <div style={{marginTop:6}}>{c.text}</div>
          </div>
        ))}
      </div>

      <form className="card glass" style={{marginTop:12}} onSubmit={submitComment}>
        <textarea className="textarea" placeholder="Ваш комментарий…" value={text} onChange={e=>setText(e.target.value)} required />
        <button className="btn primary" type="submit">Отправить</button>
      </form>
    </div>
  );
};
export default CatchDetailPage;
