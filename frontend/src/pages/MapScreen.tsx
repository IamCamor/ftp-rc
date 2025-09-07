import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import config, { featureFlags } from '../config';
import { points, saveWeatherFav, isAuthed } from '../api';
import Icon from '../components/Icon';

// простая загрузка Leaflet (CDN), чтобы карта всегда рисовалась
function useLeaflet() {
  const [ready, setReady] = useState<boolean>(!!(window as any).L);

  useEffect(() => {
    if ((window as any).L) { setReady(true); return; }

    const linkId = 'leaflet-css-cdn';
    if (!document.getElementById(linkId)) {
      const link = document.createElement('link');
      link.id = linkId;
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      link.integrity = 'sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=';
      link.crossOrigin = '';
      document.head.appendChild(link);
    }

    const scriptId = 'leaflet-js-cdn';
    if (!document.getElementById(scriptId)) {
      const s = document.createElement('script');
      s.id = scriptId;
      s.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      s.integrity = 'sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=';
      s.crossOrigin = '';
      s.onload = () => setReady(true);
      document.body.appendChild(s);
    } else {
      setReady(true);
    }
  }, []);

  return ready;
}

type Pt = { id: number|string; lat: number; lng: number; title?: string; thumbnail?: string; type?: string; };

export default function MapScreen() {
  const navigate = useNavigate();
  const mapRef = useRef<HTMLDivElement | null>(null);
  const leafletReady = useLeaflet();
  const REQUIRE_AUTH_WEATHER = (featureFlags?.requireAuthForWeatherSave ?? false);

  useEffect(() => {
    if (!leafletReady || !mapRef.current) return;
    const L = (window as any).L;
    if (!L) return;

    // инициализация карты
    const map = L.map(mapRef.current).setView([55.751244, 37.618423], 9);
    const tileUrl = (config as any)?.map?.tiles ??
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    L.tileLayer(tileUrl, { maxZoom: 19 }).addTo(map);

    // Загрузка точек
    (async () => {
      try {
        const raw = await points({ limit: 500 });
        const arr: Pt[] = Array.isArray(raw) ? raw : (Array.isArray((raw as any)?.items) ? (raw as any).items : []);
        arr.forEach((p) => {
          if (typeof p?.lat !== 'number' || typeof p?.lng !== 'number') return;
          const m = L.marker([p.lat, p.lng]).addTo(map);
          const inner = `
            <div style="display:flex;gap:8px;align-items:center">
              ${p.thumbnail ? `<img src="${p.thumbnail}" style="width:56px;height:56px;object-fit:cover;border-radius:8px" />` : ''}
              <div>
                <div style="font-weight:600">${p.title ?? 'Точка'}</div>
                <button data-id="${p.id}" class="go-detail" style="margin-top:6px;padding:6px 10px;border-radius:8px;background:#0ea5e9;color:#fff;border:0;cursor:pointer">Открыть</button>
              </div>
            </div>
          `;
          m.bindPopup(inner);

          m.on('popupopen', (e: any) => {
            const el = e.popup.getElement() as HTMLElement;
            const btn = el.querySelector('.go-detail') as HTMLButtonElement | null;
            if (btn) {
              btn.onclick = () => {
                if (p.type === 'catch') {
                  navigate(`/catch/${p.id}`);
                } else {
                  navigate(`/place/${p.id}`);
                }
              };
            }
          });
        });
      } catch (e) {
        console.error('points load error', e);
      }
    })();

    // Клик по карте → предложение сохранить точку для погоды
    map.on('click', async (ev: any) => {
      const { lat, lng } = ev.latlng || {};
      if (typeof lat !== 'number' || typeof lng !== 'number') return;

      if (REQUIRE_AUTH_WEATHER && !(await isAuthed())) {
        const go = confirm('Сохранение точки доступно только авторизованным пользователям. Войти сейчас?');
        if (go) navigate('/login');
        return;
      }

      const doSave = confirm('Сохранить эту точку для страницы погоды?');
      if (!doSave) return;

      const name = prompt('Название точки', 'Моя точка');
      try {
        await saveWeatherFav({ lat, lng, name: name || 'Моя точка' });
        alert('Точка сохранена. Проверьте на странице Погоды.');
      } catch (e) {
        console.error('saveWeatherFav error', e);
        alert('Не удалось сохранить точку');
      }
    });

    return () => map.remove();
  }, [leafletReady]);

  // Глассморфизм контейнер
  return (
    <div style={{
      position:'relative',
      width:'100%',
      height:'calc(100dvh - 116px)' // хедер+меню
    }}>
      <div ref={mapRef} style={{width:'100%',height:'100%'}} />
      <div style={{
        position:'absolute', top:12, right:12,
        backdropFilter:'blur(10px)',
        background:'rgba(255,255,255,0.3)',
        border:'1px solid rgba(255,255,255,0.4)',
        borderRadius:16, padding:'8px 10px', display:'flex', gap:8
      }}>
        <Icon name="my_location" />
        <span style={{fontWeight:600}}>Карта</span>
      </div>
    </div>
  );
}
