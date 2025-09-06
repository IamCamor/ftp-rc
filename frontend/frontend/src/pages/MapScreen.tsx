import React, { useEffect, useRef, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import api, { getWeatherFavs, saveWeatherFav } from '../api';
import { TILES_URL, UI_DIMENSIONS } from '../config';

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

function BoundsListener({ onBounds }: {onBounds: (b:L.LatLngBounds)=>void}) {
  const map = useMapEvents({
    moveend: () => onBounds(map.getBounds()),
    zoomend: () => onBounds(map.getBounds()),
    load: () => onBounds(map.getBounds()),
  });
  return null;
}

export default function MapScreen() {
  const [data, setData] = useState<Point[]>([]);
  const [error, setError] = useState<string>('');
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(()=>{
    const h = window.innerHeight - UI_DIMENSIONS.header - UI_DIMENSIONS.bottomNav;
    if (containerRef.current) containerRef.current.style.height = `${Math.max(h, 320)}px`;
  },[]);

  const loadPoints = async (b?: L.LatLngBounds) => {
    try {
      setError('');
      const bbox = b
        ? `${b.getWest().toFixed(2)},${b.getSouth().toFixed(2)},${b.getEast().toFixed(2)},${b.getNorth().toFixed(2)}`
        : undefined;

      const raw:any = await api.points({ limit: 500, bbox });
      const list = Array.isArray(raw?.items) ? raw.items
                 : Array.isArray(raw?.data) ? raw.data
                 : Array.isArray(raw) ? raw
                 : [];

      const normalized: Point[] = list.map((p:any)=>({
        id: Number(p.id ?? p.point_id ?? Math.random()*1e9),
        type: p.type ?? p.category ?? 'spot',
        lat: Number(p.lat ?? p.latitude),
        lng: Number(p.lng ?? p.longitude),
        title: p.title ?? p.name ?? '',
        photos: Array.isArray(p.photos) ? p.photos : (p.photo_url ? [p.photo_url] : []),
        catch_id: p.catch_id ? Number(p.catch_id) : undefined,
      })).filter(p => !Number.isNaN(p.lat) && !Number.isNaN(p.lng));

      setData(normalized);
    } catch (e:any) {
      setError(e?.message || 'Ошибка загрузки точек');
      setData([]);
    }
  };

  const openEntity = (p: Point) => {
    if (p.catch_id) window.location.href = `/catch/${p.catch_id}`;
    else window.location.href = `/place/${p.id}`;
  };

  const addToWeather = (p: Point) => {
    const id = `point-${p.id}`;
    saveWeatherFav({ id, name: p.title || 'Точка', lat: p.lat, lng: p.lng });
    alert('Сохранено в Избранное погоды');
  };

  return (
    <div className="p-3">
      <div className="glass card p-2 mb-3">
        <div className="flex items-center justify-between">
          <strong>Карта</strong>
          <div className="text-sm opacity-80">
            {getWeatherFavs().length ? `Избранных локаций погоды: ${getWeatherFavs().length}` : 'Нет избранных локаций'}
          </div>
        </div>
      </div>

      <div id="map-container" ref={containerRef} className="card overflow-hidden">
        <MapContainer center={defaultCenter} zoom={10} style={{width:'100%', height:'100%'}}>
          <TileLayer url={TILES_URL} attribution="&copy; OpenStreetMap contributors" />
          <BoundsListener onBounds={(b)=>loadPoints(b)} />
          {data.map(p=>(
            <Marker key={`${p.id}-${p.lat}-${p.lng}`} position={[p.lat, p.lng]} icon={pinIcon}>
              <Popup>
                <div style={{maxWidth: 240}}>
                  <div className="font-medium mb-2">{p.title || 'Точка'}</div>

                  {p.photos && p.photos.length > 0 ? (
                    <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:8}}>
                      {p.photos.slice(0,4).map((src, idx)=>(
                        <img
                          key={idx}
                          src={src}
                          alt="photo"
                          style={{cursor:'pointer', width:'100%', height:'80px', objectFit:'cover', borderRadius:'8px'} as any}
                          onClick={()=>openEntity(p)}
                        />
                      ))}
                    </div>
                  ) : (<div className="opacity-70 text-sm mb-2">Фотографий нет</div>)}

                  <div className="mt-2 flex gap-8">
                    <button className="glass-light px-3 py-2" onClick={()=>openEntity(p)}>Открыть</button>
                    <button className="glass-light px-3 py-2" onClick={()=>addToWeather(p)}>В погоду</button>
                  </div>
                </div>
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>

      {!!error && <div className="mt-3 text-red-500 text-sm">Ошибка карты: {error}</div>}
    </div>
  );
}
