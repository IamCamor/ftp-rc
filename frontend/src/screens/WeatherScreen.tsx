import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';

type SavedLocation = { id:string; name:string; lat:number; lng:number };
type WX = { temp_c?:number; wind_ms?:number; pressure?:number; source?:string };

function loadLocations(): SavedLocation[] {
  try {
    const raw = localStorage.getItem('wx_locations');
    if (!raw) return [];
    const arr = JSON.parse(raw);
    return Array.isArray(arr) ? arr : [];
  } catch { return []; }
}

function saveLocations(list: SavedLocation[]) {
  localStorage.setItem('wx_locations', JSON.stringify(list));
}

export default function WeatherScreen(){
  const [locations, setLocations] = useState<SavedLocation[]>(loadLocations());
  const [data, setData] = useState<Record<string, WX>>({});
  const [name, setName] = useState('');
  const [coords, setCoords] = useState<{lat?:number; lng?:number}>({});

  useEffect(()=>{
    (async()=>{
      const out: Record<string,WX> = {};
      for (const loc of locations) {
        try {
          const j = await api.weather(loc.lat, loc.lng);
          // Нормализуем (ожидаем from backend { temp_c, wind_ms, pressure, source })
          out[loc.id] = {
            temp_c: j?.temp_c ?? j?.main?.temp ?? null,
            wind_ms: j?.wind_ms ?? j?.wind?.speed ?? null,
            pressure: j?.pressure ?? j?.main?.pressure ?? null,
            source: j?.source ?? 'openweather'
          };
        } catch(e){
          out[loc.id] = { temp_c: undefined, wind_ms: undefined, source:'error' };
        }
      }
      setData(out);
    })();
  },[locations]);

  const add = ()=>{
    if (!name || coords.lat==null || coords.lng==null) return;
    const id = `${Date.now()}`;
    const next = [...locations, { id, name, lat:coords.lat, lng:coords.lng }];
    setLocations(next); saveLocations(next);
    setName(''); setCoords({});
  };

  const remove = (id:string)=>{
    const next = locations.filter(l=>l.id!==id);
    setLocations(next); saveLocations(next);
  };

  return (
    <div className="pt-20 pb-4 px-4 max-w-screen-sm mx-auto">
      <h1 className="text-xl font-semibold mb-3">Погода</h1>

      <div className="backdrop-blur-xl bg-white/60 border border-white/40 rounded-2xl p-3 mb-4">
        <div className="grid grid-cols-1 gap-2">
          <input
            className="px-3 py-2 rounded-xl border border-gray-200"
            placeholder="Название локации"
            value={name} onChange={e=>setName(e.target.value)}
          />
          <div className="grid grid-cols-2 gap-2">
            <input
              className="px-3 py-2 rounded-xl border border-gray-200"
              placeholder="Широта (lat)" inputMode="decimal"
              value={coords.lat ?? ''} onChange={e=>setCoords(s=>({...s,lat:parseFloat(e.target.value)}))}
            />
            <input
              className="px-3 py-2 rounded-xl border border-gray-200"
              placeholder="Долгота (lng)" inputMode="decimal"
              value={coords.lng ?? ''} onChange={e=>setCoords(s=>({...s,lng:parseFloat(e.target.value)}))}
            />
          </div>
          <button
            className="px-3 py-2 rounded-xl bg-gradient-to-r from-pink-500 to-fuchsia-600 text-white font-medium"
            onClick={add}
          >
            Добавить локацию
          </button>
        </div>
      </div>

      <div className="space-y-3">
        {locations.map(loc=>{
          const wx = data[loc.id];
          return (
            <div key={loc.id} className="backdrop-blur-xl bg-white/60 border border-white/40 rounded-2xl p-3 flex items-center justify-between">
              <div>
                <div className="font-medium">{loc.name}</div>
                <div className="text-xs text-gray-500">{loc.lat.toFixed(4)}, {loc.lng.toFixed(4)}</div>
              </div>
              <div className="text-right">
                <div className="text-sm">
                  {wx?.temp_c!=null ? `${Math.round(wx.temp_c)}°C` : '— °C'}
                </div>
                <div className="text-xs text-gray-500">
                  {wx?.wind_ms!=null ? `${wx.wind_ms.toFixed(1)} м/с` : '— м/с'}
                </div>
                <div className="text-[10px] text-gray-400">{wx?.source || ''}</div>
              </div>
              <button
                className="ml-3 text-sm text-red-500 hover:text-red-600"
                onClick={()=>remove(loc.id)}
                title="Удалить"
              >✕</button>
            </div>
          );
        })}
        {locations.length===0 && (
          <div className="text-center text-gray-500">Добавьте локации, чтобы видеть температуру и ветер</div>
        )}
      </div>
    </div>
  );
}
