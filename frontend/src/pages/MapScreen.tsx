import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import AppShell from '../components/AppShell';
import Icon from '../components/Icon';
import config from '../config';
import { points, saveWeatherFav, isAuthed } from '../api';

declare global { interface Window { L:any } }

export default function MapScreen(){
  const mapEl = useRef<HTMLDivElement>(null);
  const [error,setError] = useState<string | null>(null);
  const [ready,setReady] = useState(false);
  const navigate = useNavigate();

  useEffect(()=>{
    let aborted = false;
    (async()=>{
      try{
        if (!window.L){
          // динамически подключаем leaflet css/js (без внешних либ)
          const css = document.createElement('link');
          css.rel='stylesheet'; css.href='https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
          document.head.appendChild(css);
          await new Promise(res=>{
            const s = document.createElement('script');
            s.src='https://unpkg.com/leaflet@1.9.4/dist/leaflet.js'; s.onload=()=>res(null); document.body.appendChild(s);
          });
        }
        if (!mapEl.current) return;
        const L = window.L;
        const map = L.map(mapEl.current).setView([55.75,37.62], 9);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(map);

        const data = await points({ limit: 500 }).catch(()=>[]);
        const list = Array.isArray(data?.items) ? data.items : (Array.isArray(data)? data : []);
        list.forEach((p: any)=>{
          if (typeof p.lat!=='number' || typeof p.lng!=='number') return;
          const m = L.marker([p.lat,p.lng]).addTo(map);
          m.on('click', ()=>{
            const html = `
              <div style="min-width:180px">
                <b>${p.title ?? 'Точка'}</b><br/>
                <button id="toPlace" style="margin-top:6px">Открыть</button>
                <button id="toFav" style="margin-top:6px;margin-left:6px">Сохранить погоду</button>
              </div>`;
            m.bindPopup(html).openPopup();
            setTimeout(()=>{
              const btn = document.getElementById('toPlace');
              const fav = document.getElementById('toFav');
              btn?.addEventListener('click', ()=> navigate(`/place/${p.id}`));
              fav?.addEventListener('click', async ()=>{
                try{
                  if (config.flags?.requireAuthForWeatherSave && !isAuthed()){
                    alert('Нужно войти, чтобы сохранять точки погоды');
                    navigate('/login'); return;
                  }
                  await saveWeatherFav(p.lat,p.lng,p.title);
                  alert('Сохранено!');
                }catch(e:any){ alert(e?.message ?? 'Ошибка'); }
              });
            },0);
          });
        });

        if (!aborted) setReady(true);
      }catch(e:any){
        if (!aborted) setError(e?.message ?? 'Map init error');
      }
    })();
    return ()=>{ aborted=true; };
  },[]);

  return (
    <AppShell>
      <div className="glass card" style={{marginBottom:12}}>
        <div className="row" style={{justifyContent:'space-between'}}>
          <div className="row"><Icon name="map" /><b>Карта</b></div>
          <div className="row" style={{gap:8}}>
            <a className="btn ghost" href="/add/place"><Icon name="add_location" /> Добавить место</a>
            <a className="btn ghost" href="/add/catch"><Icon name="add_a_photo" /> Добавить улов</a>
          </div>
        </div>
      </div>
      {error && <div className="glass card">{error}</div>}
      <div ref={mapEl} style={{height:'65vh'}} className="glass"></div>
    </AppShell>
  );
}
