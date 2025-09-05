import React,{useEffect,useState} from 'react';
import { getWeatherFavs, removeWeatherFav, weather } from '../api';
import Icon from '../components/Icon';

interface Model {
  id:string; name:string; lat:number; lng:number;
  temp_c?: number|null;
  wind_ms?: number|null;
}

export default function WeatherPage(){
  const [items,setItems]=useState<Model[]>([]);
  const [loading,setLoading]=useState(false);

  const load = async ()=>{
    setLoading(true);
    const favs = getWeatherFavs();
    const enriched: Model[] = [];
    for(const f of favs){
      const w = await weather(f.lat, f.lng);
      enriched.push({ ...f, temp_c: w.temp_c??null, wind_ms: w.wind_ms??null });
    }
    setItems(enriched);
    setLoading(false);
  };

  useEffect(()=>{ load(); },[]);

  const del = (id:string)=>{
    removeWeatherFav(id);
    load();
  };

  return (
    <div className="container" style={{paddingBottom:90}}>
      <h2 style={{marginTop:12}}>Погода</h2>
      <div className="grid" style={{marginTop:12}}>
        {items.map(it=>(
          <div key={it.id} className="glass-card card row" style={{justifyContent:'space-between'}}>
            <div>
              <div><b>{it.name}</b></div>
              <div className="small">{it.lat.toFixed(4)}, {it.lng.toFixed(4)}</div>
            </div>
            <div className="row" style={{gap:12}}>
              <span className="badge"><Icon name="temp"/>{it.temp_c??'—'}°C</span>
              <span className="badge"><Icon name="wind"/>{it.wind_ms??'—'} м/с</span>
              <a className="badge" onClick={()=>del(it.id)} style={{cursor:'pointer'}}>Удалить</a>
            </div>
          </div>
        ))}
        {!items.length && !loading && <div className="small">Сохраните локацию на карте: нажмите на карту → «Сохранить локацию погоды»</div>}
        {loading && <div className="small">Обновляем…</div>}
      </div>
    </div>
  );
}
