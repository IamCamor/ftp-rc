import React,{useEffect,useRef,useState} from 'react';
import { points, getWeatherFavs, saveWeatherFav } from '../api';
import type { Point } from '../types';
import PointPinCard from '../components/PointPinCard';
import Icon from '../components/Icon';

export default function MapScreen(){
  const [items,setItems]=useState<Point[]>([]);
  const [sel,setSel]=useState<Point|null>(null);
  const [clickLatLng,setClickLatLng]=useState<{lat:number,lng:number}|null>(null);
  const mapRef = useRef<any>(null);
  const markersRef = useRef<any[]>([]);
  const clickMarkerRef = useRef<any|null>(null);
  const [fabOpen,setFabOpen]=useState(false);
  const [toast,setToast]=useState<string|null>(null);

  const openPlace=(id:number|string)=> window.navigate?.(`/place/${id}`);

  useEffect(()=>{
    if(!(window as any).L) return; // подождать загрузки Leaflet
    if(mapRef.current) return;

    const L = (window as any).L;
    const m = L.map('map',{zoomControl:true}).setView([55.75,37.61], 10);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(m);

    m.on('moveend', ()=> loadBounds());
    m.on('click',(e:any)=> {
      const {lat,lng}=e.latlng;
      setClickLatLng({lat,lng});
      if(!clickMarkerRef.current) clickMarkerRef.current = L.marker([lat,lng]).addTo(m);
      else clickMarkerRef.current.setLatLng([lat,lng]);
    });

    mapRef.current = m;
    loadBounds();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  },[]);

  async function loadBounds(){
    if(!mapRef.current) return;
    const b = mapRef.current.getBounds();
    const bbox:[number,number,number,number] = [b.getWest(), b.getSouth(), b.getEast(), b.getNorth()];
    const data = await points({limit:500,bbox});
    setItems(data);
    // markers
    const L = (window as any).L;
    markersRef.current.forEach(m=>m.remove());
    markersRef.current = [];
    data.forEach(p=>{
      const mk = L.marker([p.lat,p.lng]).addTo(mapRef.current)
        .on('click',()=> setSel(p));
      markersRef.current.push(mk);
    });
  }

  const saveWeatherPoint = ()=>{
    if(!clickLatLng) return;
    const id = `${clickLatLng.lat.toFixed(4)},${clickLatLng.lng.toFixed(4)}`;
    saveWeatherFav({ id, name:`Метка ${id}`, lat:clickLatLng.lat, lng:clickLatLng.lng, created_at:Date.now() });
    setToast('Локация добавлена в Погоду');
    setTimeout(()=>setToast(null),1200);
  };

  return (
    <div className="map-wrap">
      <div id="map"></div>

      {/* нижняя стеклянная панель */}
      <div className="map-overlay">
        <div className="panel glass">
          {!sel && <div className="small">Нажмите на пин чтобы посмотреть место. Нажмите на карту — поставится временная метка.</div>}
          {sel && <PointPinCard point={sel} onOpen={openPlace}/>}
        </div>
      </div>

      {/* FAB */}
      <div className="fab">
        {fabOpen && (
          <div className="fab-menu">
            <div className="action" onClick={()=>window.navigate?.('/add-catch')} style={{cursor:'pointer'}}>
              <span className="chip">Добавить улов</span>
              <div className="btn"><Icon name="addCatch"/></div>
            </div>
            <div className="action" onClick={()=>window.navigate?.('/add-place')} style={{cursor:'pointer'}}>
              <span className="chip">Добавить точку</span>
              <div className="btn"><Icon name="addPlace"/></div>
            </div>
            {clickLatLng && (
              <div className="action" onClick={saveWeatherPoint} style={{cursor:'pointer'}}>
                <span className="chip">Сохранить локацию погоды</span>
                <div className="btn"><Icon name="bookmark"/></div>
              </div>
            )}
          </div>
        )}
        <button className="btn" onClick={()=>setFabOpen(v=>!v)}><Icon name="plus" weight={700}/></button>
      </div>

      {toast && <div className="toast">{toast}</div>}
    </div>
  );
}
