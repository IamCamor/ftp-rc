import React, { useEffect, useState } from 'react';
import config from '../config';
import Icon from '../components/Icon';

type Fav = { lat:number; lng:number; name?:string };

export default function WeatherPage(){
  const [favs, setFavs] = useState<Fav[]>([]);

  useEffect(() => {
    try{
      const raw = localStorage.getItem('weatherFavs');
      const parsed = raw ? JSON.parse(raw) : [];
      const arr = Array.isArray(parsed) ? parsed : [];
      setFavs(arr.filter(v => typeof v?.lat==='number' && typeof v?.lng==='number'));
    } catch{
      setFavs([]);
    }
  }, []);

  if (!favs.length){
    return (
      <div style={{padding:16}}>
        <div style={{
          backdropFilter:'blur(10px)',
          background:'rgba(255,255,255,0.35)',
          border:'1px solid rgba(255,255,255,0.4)',
          borderRadius:16,
          padding:16
        }}>
          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:8}}>
            <Icon name="cloud" />
            <b>Погода</b>
          </div>
          <div>У вас пока нет сохранённых точек. Откройте Карту и кликните по месту, чтобы сохранить точку.</div>
        </div>
      </div>
    );
  }

  return (
    <div style={{padding:16, display:'grid', gap:12}}>
      {favs.map((f, i) => (
        <div key={i} style={{
          backdropFilter:'blur(10px)',
          background:'rgba(255,255,255,0.35)',
          border:'1px solid rgba(255,255,255,0.4)',
          borderRadius:16, padding:16
        }}>
          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:6}}>
            <Icon name="place" />
            <b>{f.name || `Точка ${i+1}`}</b>
          </div>
          <div style={{fontSize:14,opacity:.8}}>Координаты: {f.lat.toFixed(5)}, {f.lng.toFixed(5)}</div>
          {/* Здесь можно подставить виджет прогноза или запрос на ваш бек */}
        </div>
      ))}
    </div>
  );
}
