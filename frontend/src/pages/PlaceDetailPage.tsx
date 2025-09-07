import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { placeById } from '../api';
import MediaGrid from '../components/MediaGrid';

const PlaceDetailPage: React.FC = () => {
  const { id } = useParams();
  const [data, setData] = useState<any>(null);
  const [err, setErr] = useState('');

  useEffect(()=>{
    if (!id) return;
    placeById(id).then(setData).catch((e)=> setErr(e.message||'Ошибка'));
  },[id]);

  if (err) return <div className="container"><div className="card glass" style={{color:'#ffb4b4'}}>{err}</div></div>;
  if (!data) return <div className="container"><div className="card glass">Загрузка…</div></div>;

  const photos = Array.isArray(data.photos) ? data.photos.map((url:string)=>({url})) : (data.photo_url? [{url:data.photo_url}] : []);

  return (
    <div className="container">
      <h2 className="h2">{data.title || `Место #${id}`}</h2>
      <div className="muted" style={{marginBottom:8}}>{data.description || '—'}</div>
      <div className="muted">{data.lat?.toFixed?.(4)}, {data.lng?.toFixed?.(4)}</div>

      <div style={{marginTop:12}}>
        <MediaGrid items={photos} />
      </div>
    </div>
  );
};
export default PlaceDetailPage;
