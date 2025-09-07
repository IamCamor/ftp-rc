import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { points, saveWeatherFav } from '../api';
import { loadLeaflet } from '../utils/leafletLoader';
import PointPinCard from '../components/PointPinCard';
import Icon from '../components/Icon';
import config from '../config';

const MapScreen: React.FC = () => {
  const nav = useNavigate();
  const mapRef = useRef<any>(null);
  const layerRef = useRef<any>(null);
  const [list, setList] = useState<any[]>([]);
  const [selected, setSelected] = useState<any|null>(null);
  const mapEl = useRef<HTMLDivElement>(null);

  // загрузка точек
  useEffect(()=>{
    async function run(){
      try{
        const arr = await points(undefined, 500);
        setList(Array.isArray(arr)? arr : []);
      }catch(e){ console.error('points load error', e); }
    }
    run();
  },[]);

  // инициализация карты
  useEffect(()=>{
    let map:any, L:any, markers:any;
    async function init(){
      if (!mapEl.current) return;
      L = await loadLeaflet();

      map = L.map(mapEl.current).setView([55.75, 37.62], 10);
      mapRef.current = map;

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{
        attribution:'© OpenStreetMap',
      }).addTo(map);

      markers = L.layerGroup().addTo(map);
      layerRef.current = markers;

      // Клик по карте — добавить в избранную погоду
      map.on('click', (ev:any)=>{
        const { lat, lng } = ev.latlng;
        saveWeatherFav({lat, lng, title:`Выбранная точка`});
        alert('Точка добавлена в Погоду');
      });
    }
    init();
    return ()=>{ if (mapRef.current) mapRef.current.remove(); };
  },[]);

  // отрисовка маркеров
  useEffect(()=>{
    (async ()=>{
      const L = await loadLeaflet();
      const g = layerRef.current;
      if (!g) return;
      g.clearLayers();

      (Array.isArray(list) ? list : []).forEach((p:any)=>{
        const m = L.marker([p.lat, p.lng]).addTo(g);
        m.on('click', ()=>{
          setSelected(p);
        });
      });
    })();
  },[list]);

  return (
    <div className="container">
      <div className="row" style={{justifyContent:'space-between', marginBottom:8}}>
        <h2 className="h2">Карта</h2>
        <div className="row" style={{gap:6}}>
          <button className="btn" onClick={()=>nav('/add/place')} title="Добавить место">
            <Icon name={config.icons.add} /> Место
          </button>
          <button className="btn" onClick={()=>nav('/add/catch')} title="Добавить улов">
            <Icon name={config.icons.add} /> Улов
          </button>
        </div>
      </div>

      <div ref={mapEl} className="leaflet-container glass" />

      {selected && (
        <div style={{marginTop:12}}>
          <PointPinCard p={{
            id: selected.id,
            lat: selected.lat,
            lng: selected.lng,
            title: selected.title || selected.name,
            photos: selected.photos,
            kind: selected.type || 'place'
          }}/>
        </div>
      )}
    </div>
  );
};
export default MapScreen;
