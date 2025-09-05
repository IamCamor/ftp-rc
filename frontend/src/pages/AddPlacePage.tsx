import React, {useEffect, useRef, useState} from 'react';
import { addPlace } from '../api';
import Icon from '../components/Icon';

export default function AddPlacePage(){
  const [form,setForm]=useState<any>({ title:'', type:'spot', lat:'', lng:'' });
  const [pickMap,setPickMap]=useState(false);
  const mapRef = useRef<any>(null);
  const tempMarker = useRef<any>(null);
  const [hint,setHint]=useState<string|null>(null);

  const setField=(k:string,v:any)=> setForm((f:any)=>({...f,[k]:v}));

  useEffect(()=>{
    if(!pickMap) return;
    if(!mapRef.current){
      if(!(window as any).L){ setHint('Карта загружается…'); return; }
      const L = (window as any).L;
      const m = L.map('pick-map2',{zoomControl:true}).setView([55.75,37.61], 11);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(m);
      m.on('click',(e:any)=>{
        const {lat,lng}=e.latlng;
        if(!tempMarker.current) tempMarker.current = L.marker([lat,lng]).addTo(m)
        else tempMarker.current.setLatLng([lat,lng]);
        setField('lat', lat.toFixed(6));
        setField('lng', lng.toFixed(6));
      });
      mapRef.current = m;
    } else {
      mapRef.current.invalidateSize();
    }
  },[pickMap]);

  const submit=async(e:React.FormEvent)=>{
    e.preventDefault();
    try{
      await addPlace({ ...form, lat:parseFloat(form.lat), lng:parseFloat(form.lng) });
      setHint('Точка добавлена');
      setTimeout(()=>window.navigate?.('/map'),700);
    }catch{
      setHint('Ошибка сохранения');
    }
  };

  return (
    <div className="container" style={{paddingBottom:90}}>
      <h2 style={{marginTop:12}}>Добавить точку</h2>
      <form className="form-grid glass card" onSubmit={submit}>
        <input className="input" placeholder="Название" value={form.title} onChange={e=>setField('title',e.target.value)}/>
        <select className="select" value={form.type} onChange={e=>setField('type',e.target.value)}>
          <option value="spot">Перспективное место</option>
          <option value="catch">Улов</option>
          <option value="shop">Магазин</option>
          <option value="slip">Слип</option>
          <option value="camp">Кемпинг</option>
        </select>
        <div className="form-inline">
          <input className="input" placeholder="Широта" value={form.lat} onChange={e=>setField('lat',e.target.value)}/>
          <input className="input" placeholder="Долгота" value={form.lng} onChange={e=>setField('lng',e.target.value)}/>
        </div>

        <div className="row" style={{gap:10}}>
          <button type="button" className="button ghost" onClick={()=>setPickMap(v=>!v)}><Icon name="location"/> Выбрать на карте</button>
        </div>
        {pickMap && <div id="pick-map2" style={{height:300,borderRadius:12,overflow:'hidden',border:'1px solid var(--stroke)'}} />}

        <div className="row" style={{justifyContent:'flex-end',gap:10}}>
          <button type="button" className="button ghost" onClick={()=>window.navigate?.('/map')}>Отмена</button>
          <button type="submit" className="button primary">Сохранить</button>
        </div>
      </form>
      {hint && <div className="toast">{hint}</div>}
    </div>
  );
}
