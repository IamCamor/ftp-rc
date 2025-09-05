import React, {useEffect, useRef, useState} from 'react';
import { addCatch, upload, weather } from '../api';
import Icon from '../components/Icon';

export default function AddCatchPage(){
  const [form,setForm]=useState<any>({ species:'', method:'', bait:'', gear:'', caption:'', lat:'', lng:'', caught_at:'' });
  const [files,setFiles]=useState<File[]>([]);
  const [pickMap,setPickMap]=useState(false);
  const mapRef = useRef<any>(null);
  const tempMarker = useRef<any>(null);
  const [hint,setHint] = useState<string|null>(null);

  const setField=(k:string,v:any)=> setForm((f:any)=>({...f,[k]:v}));

  // встраиваем выбор на карте
  useEffect(()=>{
    if(!pickMap) return;
    if(!mapRef.current){
      if(!(window as any).L){ setHint('Карта загружается…'); return; }
      const L = (window as any).L;
      const m = L.map('pick-map',{zoomControl:true}).setView([55.75,37.61], 11);
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

  const onFiles=(e:React.ChangeEvent<HTMLInputElement>)=>{
    const list = e.target.files ? Array.from(e.target.files) : [];
    setFiles(list);
  };

  const autofillWeather = async ()=>{
    const lat = parseFloat(form.lat), lng=parseFloat(form.lng);
    if(!lat || !lng) return setHint('Сначала укажите координаты');
    const dt = form.caught_at ? Math.floor(new Date(form.caught_at).getTime()/1000) : undefined;
    const w = await weather(lat,lng,dt);
    setHint(`Погода: ${w.temp_c??'—'}°C, ветер ${w.wind_ms??'—'} м/с`);
    setForm((f:any)=>({...f, weather_temp_c:w.temp_c, weather_wind_ms:w.wind_ms }));
  };

  const submit=async(e:React.FormEvent)=>{
    e.preventDefault();
    try{
      let media_url = undefined;
      if(files.length){
        const r = await upload(files);
        media_url = r.urls?.[0];
      }
      const payload = {...form, media_url};
      await addCatch(payload);
      setHint('Улов добавлен');
      setTimeout(()=>window.navigate?.('/feed'),800);
    }catch(err:any){
      setHint('Ошибка сохранения');
    }
  };

  return (
    <div className="container" style={{paddingBottom:90}}>
      <h2 style={{marginTop:12}}>Добавить улов</h2>
      <form className="form-grid glass card" onSubmit={submit}>
        <div className="form-inline">
          <input className="input" placeholder="Вид рыбы" value={form.species} onChange={e=>setField('species',e.target.value)}/>
          <input className="input" placeholder="Метод" value={form.method} onChange={e=>setField('method',e.target.value)}/>
        </div>
        <div className="form-inline">
          <input className="input" placeholder="Приманка" value={form.bait} onChange={e=>setField('bait',e.target.value)}/>
          <input className="input" placeholder="Снасть" value={form.gear} onChange={e=>setField('gear',e.target.value)}/>
        </div>
        <textarea className="input" placeholder="Комментарий" value={form.caption} onChange={e=>setField('caption',e.target.value)} />

        <div className="form-inline">
          <input className="input" placeholder="Широта" value={form.lat} onChange={e=>setField('lat',e.target.value)}/>
          <input className="input" placeholder="Долгота" value={form.lng} onChange={e=>setField('lng',e.target.value)}/>
        </div>

        <div className="row" style={{gap:10}}>
          <button type="button" className="button ghost" onClick={()=>setPickMap(v=>!v)}><Icon name="location"/> Выбрать на карте</button>
          <input type="datetime-local" className="input" value={form.caught_at} onChange={e=>setField('caught_at',e.target.value)} />
          <button type="button" className="button ghost" onClick={autofillWeather}><Icon name="weather"/> Подставить погоду</button>
        </div>

        {pickMap && <div id="pick-map" style={{height:300,borderRadius:12,overflow:'hidden',border:'1px solid var(--stroke)'}} />}

        <div>
          <label className="small">Фото/видео</label>
          <input type="file" multiple accept="image/*,video/*" onChange={onFiles}/>
        </div>

        <div className="row" style={{justifyContent:'flex-end',gap:10}}>
          <button type="button" className="button ghost" onClick={()=>window.navigate?.('/map')}>Отмена</button>
          <button type="submit" className="button primary">Сохранить</button>
        </div>
      </form>
      {hint && <div className="toast">{hint}</div>}
    </div>
  );
}
