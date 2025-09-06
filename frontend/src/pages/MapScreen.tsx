import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { points, saveWeatherFav } from '../api';
import { loadLeaflet } from '../utils/leafletLoader';

type Point = { id: number|string; lat:number; lng:number; type?:'place'|'catch'|string; title?:string; species?:string; media?:string[]; photo_url?:string; };

const DEFAULT_CENTER:[number,number] = [55.75, 37.61];
const DEFAULT_ZOOM = 10;

const MapScreen:React.FC = () => {
  const nav = useNavigate();
  const mapEl = useRef<HTMLDivElement|null>(null);
  const mapRef = useRef<any>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let canceled = false;
    (async () => {
      const L = await loadLeaflet();
      if (canceled) return;
      const map = L.map(mapEl.current!).setView(DEFAULT_CENTER, DEFAULT_ZOOM);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19, attribution:'&copy; OpenStreetMap'}).addTo(map);
      mapRef.current = map; setReady(true);

      map.on('click', async (e:any) => {
        const lat = e.latlng.lat, lng = e.latlng.lng;
        const m = L.marker([lat,lng]).addTo(map);
        m.bindPopup(`
          <div style="padding:6px;min-width:220px">
            <b>Новая точка</b><br/>${lat.toFixed(5)}, ${lng.toFixed(5)}<br/><br/>
            <button id="btnAddPlace" style="padding:6px 10px;border-radius:10px;border:1px solid #fff3;background:#ffffff14;color:#fff">Добавить место</button>
            <button id="btnSaveWeather" style="padding:6px 10px;border-radius:10px;border:1px solid #fff3;background:#ffffff14;color:#fff;margin-left:6px">В погоду</button>
          </div>
        `).openPopup();
        setTimeout(() => {
          document.getElementById('btnAddPlace')?.addEventListener('click', () => nav(`/add/place?lat=${lat}&lng=${lng}`), { once:true });
          document.getElementById('btnSaveWeather')?.addEventListener('click', async () => {
            await saveWeatherFav({ lat, lng, name:`Точка ${lat.toFixed(3)},${lng.toFixed(3)}` });
            alert('Сохранено в избранные точки погоды');
          }, { once:true });
        }, 0);
      });
    })();
    return () => { canceled = true; try { mapRef.current?.remove(); } catch {} };
  }, [nav]);

  useEffect(() => {
    if (!ready) return;
    (async () => {
      try {
        const L = (window as any).L;
        const raw = await points({ limit: 500 });
        const list: Point[] = Array.isArray(raw) ? raw : [];
        list.forEach(p => {
          const m = L.marker([p.lat, p.lng]).addTo(mapRef.current);
          const img = (p.media && p.media[0]) || p.photo_url || '';
          const title = (p.title || p.species || 'Точка').replace(/</g,'&lt;').replace(/>/g,'&gt;');
          const href = p.type === 'catch' ? `/catch/${p.id}` : `/place/${p.id}`;
          const html = `
            <div style="min-width:220px">
              ${img ? `<img src="${img}" style="width:100%;height:120px;object-fit:cover;border-radius:10px;margin-bottom:6px" />` : ''}
              <div style="font-weight:600;margin-bottom:6px">${title}</div>
              <a href="${href}" class="leaflet-popup-link">Открыть</a>
            </div>`;
          m.bindPopup(html);
          m.on('popupopen', () => {
            const a = document.querySelector('.leaflet-popup a.leaflet-popup-link') as HTMLAnchorElement | null;
            a?.addEventListener('click', (ev) => { ev.preventDefault(); nav(a.getAttribute('href') || '/'); }, { once:true });
          });
        });
      } catch (e) {
        console.error('points load error', e);
      }
    })();
  }, [ready, nav]);

  return (
    <div className="map-wrap">
      <div id="map" ref={mapEl} className="glass" />
      <div className="fab">
        <button className="btn" onClick={() => nav('/add/place')}><span className="material-symbols-rounded">add_location_alt</span>Место</button>
        <button className="btn" onClick={() => nav('/add/catch')}><span className="material-symbols-rounded">add_circle</span>Улов</button>
      </div>
    </div>
  );
};
export default MapScreen;
