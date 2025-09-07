import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { points, saveWeatherFav, isAuthed } from '../api';
import config from '../config';
import Confirm from '../components/Confirm';
import { pushToast } from '../components/Toast';

// ленивый загрузчик Leaflet (ожидается utils/leafletLoader.ts, если нет — инлайним простой)
async function loadLeaflet() {
  const L = await import('leaflet');
  // css пусть уже подключён в index.html; если нет — карта всё равно работает, только без стилей
  return L;
}

type MapPoint = {
  id: number|string;
  lat: number; lng: number;
  type?: 'place'|'catch';
  title?: string;
  preview?: string; // url
};

const MapScreen: React.FC = () => {
  const nav = useNavigate();
  const mapRef = useRef<any>(null);
  const [pts, setPts] = useState<MapPoint[]>([]);
  const [L, setL] = useState<any>(null);

  // confirm dialog state
  const [confirmOpen, setConfirmOpen] = useState(false);
  const pendingRef = useRef<{lat:number; lng:number; title?:string} | null>(null);

  useEffect(()=> {
    (async ()=>{
      const _L = await loadLeaflet(); setL(_L);
      const data = await points(undefined, 500).catch(()=>[]);
      setPts(Array.isArray(data) ? data : []);
      // init map
      const m = _L.map('map', { center:[55.75,37.6], zoom:10 });
      _L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(m);
      mapRef.current = m;

      // отрисовка
      (Array.isArray(data)? data:[]).forEach((p:any)=>{
        const marker = _L.marker([p.lat, p.lng]).addTo(m);
        const html = `
          <div style="min-width:180px">
            <div style="font-weight:600;margin-bottom:6px">${p.title || 'Точка'}</div>
            ${p.preview ? `<img src="${p.preview}" alt="" style="width:100%;height:100px;object-fit:cover;border-radius:8px" />`: ''}
            <div style="margin-top:6px;display:flex;gap:8;justify-content:flex-end">
              <a href="/place/${p.id}" data-id="${p.id}" data-type="${p.type||'place'}">Открыть</a>
            </div>
          </div>`;
        marker.bindPopup(html);
        marker.on('popupopen', (e:any)=>{
          // перехватить клик по ссылке, чтобы уйти через router
          setTimeout(()=>{
            const el = (e as any).popup?._contentNode?.querySelector('a[data-id]');
            if(el){
              el.addEventListener('click', (ev:any)=>{
                ev.preventDefault();
                const id = el.getAttribute('data-id');
                const t = el.getAttribute('data-type');
                nav(t==='catch'? `/catch/${id}` : `/place/${id}`);
              }, { once:true });
            }
          }, 0);
        });
      });

      // клик по карте — предложить сохранить в погоду
      m.on('click', (ev:any)=>{
        const { lat, lng } = ev.latlng || {};
        if (!lat || !lng) return;
        pendingRef.current = { lat, lng, title: `Точка ${lat.toFixed(4)}, ${lng.toFixed(4)}` };
        setConfirmOpen(true);
      });
    })();
  }, [nav]);

  function onCancel(){ setConfirmOpen(false); pendingRef.current = null; }
  function onConfirm(){
    setConfirmOpen(false);
    const p = pendingRef.current; pendingRef.current = null;
    if(!p) return;
    if (config.auth.requireAuthForWeatherSave && !isAuthed()){
      if (confirm('Сохранять точки могут только авторизованные.\nПерейти к авторизации?')){
        window.location.href = '/login';
      }
      return;
    }
    saveWeatherFav(p);
    pushToast('Точка сохранена для страницы погоды');
  }

  return (
    <div className="container">
      <div className="glass card" style={{marginBottom:8}}>
        Нажмите по карте, чтобы предложить сохранить точку в “Погоду”. {config.auth.requireAuthForWeatherSave?'(Требуется вход)':''}
      </div>
      <div id="map" style={{height:'70vh', width:'100%', borderRadius:16, overflow:'hidden'}} />
      <Confirm
        open={confirmOpen}
        title="Сохранить точку?"
        text="Добавить выбранную точку на страницу погоды?"
        confirmText="Сохранить"
        cancelText="Отмена"
        onConfirm={onConfirm}
        onCancel={onCancel}
      />
    </div>
  );
};

export default MapScreen;
