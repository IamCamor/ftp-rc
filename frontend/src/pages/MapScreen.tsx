import React, { useEffect, useRef, useState } from 'react';
import api, { getWeatherFavs, saveWeatherFav } from '../api';
import { TILES_URL, UI_DIMENSIONS } from '../config';
import Icon from '../components/Icon';
import 'leaflet/dist/leaflet.css';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from 'react-leaflet';
import L from 'leaflet';

type Point = {
  id: number;
  type?: string;
  lat: number;
  lng: number;
  title?: string;
  photos?: string[];
  catch_id?: number;
};

const defaultCenter: [number, number] = [55.751244, 37.618423];
const pinIcon = new L.Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25,41],
  iconAnchor: [12,41],
});

function BoundsListener({ onBounds, onClick }: {onBounds:(b:L.LatLngBounds)=>void; onClick:(lat:number,lng:number)=>void}) {
  useMapEvents({
    moveend: (e)=> onBounds(e.target.getBounds()),
    zoomend: (e)=> onBounds(e.target.getBounds()),
    load: (e)=> onBounds(e.target.getBounds()),
    click: (e)=> onClick(e.latlng.lat, e.latlng.lng),
  });
  return null;
}

export default function MapScreen() {
  const [data,setData] = useState<Point[]>([]);
  const [error,setError] = useState('');
  const [draft,setDraft] = useState<{lat:number;lng:number}|null>(null);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(()=>{
    const h = window.innerHeight - UI_DIMENSIONS.header - UI_DIMENSIONS.bottomNav;
    if (ref.current) ref.current.style.height = `${Math.max(h, 320)}px`;
  },[]);

  const load = async(b?:L.LatLngBounds)=>{
    try{
      setError('');
      const bbox = b ? `${b.getWest().toFixed(2)},${b.getSouth().toFixed(2)},${b.getEast().toFixed(2)},${b.getNorth().toFixed(2)}` : undefined;
      const raw:any = await api.points({limit:500, bbox});
      const list = Array.isArray(raw?.items) ? raw.items
                 : Array.isArray(raw?.data) ? raw.data
                 : Array.isArray(raw) ? raw : [];
      const normalized: Point[] = list.map((p:any)=>({
        id: Number(p.id ?? p.point_id ?? Math.random()*1e9),
        type: p.type ?? p.category ?? 'spot',
        lat: Number(p.lat ?? p.latitude),
        lng: Number(p.lng ?? p.longitude),
        title: p.title ?? p.name ?? '',
        photos: Array.isArray(p.photos) ? p.photos : (p.photo_url ? [p.photo_url] : []),
        catch_id: p.catch_id ? Number(p.catch_id) : undefined,
      })).filter(p=>!Number.isNaN(p.lat)&&!Number.isNaN(p.lng));
      setData(normalized);
    }catch(e:any){
      setError(e?.message || 'Ошибка загрузки точек');
      setData([]);
    }
  };

  const openEntity = (p:Point)=> { window.location.href = p.catch_id ? `/catch/${p.catch_id}` : `/place/${p.id}`; };

  const addToWeather = (lat:number,lng:number,name='Точка')=>{
    const id = `point-${lat.toFixed(4)}-${lng.toFixed(4)}`;
    saveWeatherFav({ id, name, lat, lng });
    alert('Локация сохранена на странице погоды');
  };

  const savePlace = async ()=>{
    if(!draft) return;
    try{
      await api.addPlace({ lat: draft.lat, lng: draft.lng, title:'Моё место' });
      setDraft(null);
      await load();
      addToWeather(draft.lat,draft.lng,'Моё место');
    }catch(e:any){
      alert('Не удалось сохранить место: '+(e?.message||''));
    }
  };

  return (
    <div className="p-3">
      <div className="glass card mb-3" style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:12}}>
        <div><strong>Карта</strong></div>
        <div style={{display:'flex',gap:8}}>
          <a className="btn" href="/add-place"><Icon name="add_location" />&nbsp;Добавить точку</a>
          <a className="btn" href="/add-catch"><Icon name="add_photo_alternate" />&nbsp;Добавить улов</a>
        </div>
      </div>

      <div ref={ref} className="card" style={{overflow:'hidden'}}>
        <MapContainer center={defaultCenter} zoom={10} style={{width:'100%',height:'100%'}}>
          <TileLayer url={TILES_URL} attribution="&copy; OpenStreetMap contributors"/>
          <BoundsListener
            onBounds={(b)=>load(b)}
            onClick={(lat,lng)=> setDraft({lat,lng}) }
          />

          {data.map(p=>(
            <Marker key={`${p.id}-${p.lat}-${p.lng}`} position={[p.lat,p.lng]} icon={pinIcon}>
              <Popup>
                <div style={{maxWidth:240}}>
                  <div className="font-medium mb-2">{p.title || 'Точка'}</div>
                  {p.photos && p.photos.length ? (
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:8}}>
                      {p.photos.slice(0,4).map((src,idx)=>(
                        <img key={idx} src={src} alt="" style={{width:'100%',height:'80px',objectFit:'cover',borderRadius:8,cursor:'pointer'}} onClick={()=>openEntity(p)} />
                      ))}
                    </div>
                  ) : <div className="opacity-70 text-sm mb-2">Фото не прикреплены</div>}
                  <div className="mt-2" style={{display:'flex',gap:8}}>
                    <button className="btn" onClick={()=>openEntity(p)}><Icon name="open_in_new" />&nbsp;Открыть</button>
                    <button className="btn" onClick={()=>addToWeather(p.lat,p.lng,p.title||'Точка')}><Icon name="cloud_download" />&nbsp;В погоду</button>
                  </div>
                </div>
              </Popup>
            </Marker>
          ))}

          {draft && (
            <Marker position={[draft.lat,draft.lng]} icon={pinIcon}>
              <Popup>
                <div style={{maxWidth:220}}>
                  Новая точка<br/>
                  {draft.lat.toFixed(5)}, {draft.lng.toFixed(5)}
                  <div className="mt-2" style={{display:'flex',gap:8}}>
                    <button className="btn" onClick={savePlace}><Icon name="save" />&nbsp;Сохранить</button>
                    <button className="btn" onClick={()=>setDraft(null)}><Icon name="close" />&nbsp;Отмена</button>
                  </div>
                </div>
              </Popup>
            </Marker>
          )}
        </MapContainer>
      </div>

      {!!error && <div className="mt-3" style={{color:'#ff9b9b'}}>Ошибка карты: {error}</div>}

      <div className="glass card mt-3" style={{display:'flex',justifyContent:'space-between'}}>
        <div>Избранные локации погоды: {getWeatherFavs().length || 0}</div>
        <a className="btn" href="/weather"><Icon name="weather_mix" />&nbsp;Открыть погоду</a>
      </div>
    </div>
  );
}
