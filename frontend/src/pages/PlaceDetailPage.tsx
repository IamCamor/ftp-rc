import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { getPlaceById } from '../api';

const PlaceDetailPage:React.FC = () => {
  const { id } = useParams();
  const [data, setData] = useState<any>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    (async() => {
      try { setData(await getPlaceById(id!)); }
      catch(e:any){ setErr(e?.message || 'Ошибка загрузки'); }
    })();
  }, [id]);

  if (err) return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Место</h2>
        <div className="subtle">{err}</div>
      </div>
    </div>
  );

  if (!data) return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Место</h2>
        <div className="subtle">Загрузка…</div>
      </div>
    </div>
  );

  const photos:string[] = data.photos || data.media || (data.photo_url ? [data.photo_url] : []) || [];

  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>{data.title || 'Место'}</h2>
        {photos.length > 0 && (
          <div style={{display:'grid', gridTemplateColumns:'repeat(auto-fill,minmax(160px,1fr))', gap:8, margin:'8px 0'}}>
            {photos.map((src:string, i:number)=> (
              <img key={i} src={src} alt="" style={{width:'100%', height:120, objectFit:'cover', borderRadius:12}}/>
            ))}
          </div>
        )}
        <div className="subtle" style={{margin:'8px 0'}}>
          {data.description || 'Нет описания'}
        </div>
        <div style={{display:'flex', gap:12, flexWrap:'wrap', marginTop:6}}>
          <span className="subtle"><span className="material-symbols-rounded">location_on</span> {data.lat?.toFixed?.(5)}, {data.lng?.toFixed?.(5)}</span>
          {data.water_type && <span className="subtle"><span className="material-symbols-rounded">waves</span> {data.water_type}</span>}
          {data.access && <span className="subtle"><span className="material-symbols-rounded">lock_open</span> {data.access}</span>}
        </div>
        <div style={{display:'flex', gap:8, marginTop:12}}>
          <Link to="/map" className="btn"><span className="material-symbols-rounded">map</span> На карту</Link>
          <Link to="/feed" className="btn"><span className="material-symbols-rounded">home</span> В ленту</Link>
        </div>
      </div>
    </div>
  );
};
export default PlaceDetailPage;
