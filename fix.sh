#!/usr/bin/env bash
set -euo pipefail

ZIP_NAME="ftp-hotfix-comments-map-weather.zip"
STAGE=".hotfix_stage_$$"

# Очистка при выходе
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

# ---- Структура архива ----
mkdir -p "$STAGE/backend/app/Http/Controllers/Api"
mkdir -p "$STAGE/frontend/src/components"
mkdir -p "$STAGE/frontend/src/screens"
mkdir -p "$STAGE/frontend/src/lib"
mkdir -p "$STAGE/frontend/src"
mkdir -p "$STAGE/frontend/public"
mkdir -p "$STAGE/frontend/src/styles"

########################################
# BACKEND: CommentController.php (фикс 422 + гибкие поля)
########################################
cat > "$STAGE/backend/app/Http/Controllers/Api/CommentController.php" <<'PHP'
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CommentController extends Controller
{
    public function store(Request $r, $catchId)
    {
        // Принимаем text | comment | body | message
        $raw = $r->input('text', $r->input('comment', $r->input('body', $r->input('message', null))));
        $text = is_string($raw) ? trim($raw) : '';

        if ($text === '') {
            return response()->json([
                'message' => 'Validation error',
                'errors' => ['text' => ['Поле комментария обязательно']],
            ], 422);
        }

        $userId = optional($r->user())->id;
        $parentId = $r->integer('parent_id');
        $now = now();

        // Набор полей к insert — минимально совместимый
        $insert = [
            'catch_id'   => (int)$catchId,
            'user_id'    => $userId,
            'parent_id'  => $parentId ?: null,
            'text'       => $text,
            'created_at' => $now,
            'updated_at' => $now,
        ];

        // Если есть колонка is_approved — одобряем сразу
        if (Schema::hasColumn('catch_comments', 'is_approved')) {
            $insert['is_approved'] = 1;
        }

        // Опционально поддержим author_name, если колонка существует
        if (!$userId && Schema::hasColumn('catch_comments', 'author_name')) {
            $guest = trim((string)$r->input('guest_name', ''));
            $insert['author_name'] = $guest !== '' ? $guest : null;
        }

        $id = DB::table('catch_comments')->insertGetId($insert);

        // Вернём карточку комментария с именем и аватаром (если есть)
        $select = "
            cc.id, cc.catch_id, cc.parent_id, cc.text, cc.created_at
        ";
        if (Schema::hasColumn('catch_comments','is_approved')) {
            $select .= ", cc.is_approved";
        }

        $avatarExpr = "COALESCE(u.avatar_url, u.photo_url, '')";
        $nameExpr   = "COALESCE(u.name, 'Гость')";
        if (Schema::hasColumn('catch_comments','author_name')) {
            $nameExpr = "COALESCE(u.name, cc.author_name, 'Гость')";
        }

        $item = DB::table('catch_comments as cc')
            ->leftJoin('users as u','u.id','=','cc.user_id')
            ->selectRaw($select . ",
                $nameExpr as author_name,
                $avatarExpr as author_avatar
            ")
            ->where('cc.id', $id)
            ->first();

        return response()->json(['item' => $item], 201);
    }
}
PHP

########################################
# FRONTEND: api.ts — функции points/feed/weather + комменты
########################################
cat > "$STAGE/frontend/src/lib/api.ts" <<'TS'
export const API_BASE = (window as any).__API__ || 'https://api.fishtrackpro.ru/api/v1';

async function req(path: string, init?: RequestInit) {
  const res = await fetch(`${API_BASE}${path}`, {
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' , ...(init?.headers||{}) },
    ...init
  });
  if (!res.ok) {
    let p = null; try { p = await res.text(); } catch {}
    console.error('HTTP', res.status, path, p);
    throw new Error(String(res.status));
  }
  const ct = res.headers.get('content-type')||'';
  return ct.includes('application/json') ? res.json() : res.text();
}

export const api = {
  points: (params: {limit?:number; filter?:string; bbox?: string}) => {
    const q = new URLSearchParams();
    if (params.limit) q.set('limit', String(params.limit));
    if (params.filter) q.set('filter', params.filter);
    if (params.bbox) q.set('bbox', params.bbox);
    return req(`/map/points?${q.toString()}`);
  },
  feed: (params: {limit?:number; offset?:number}) => {
    const q = new URLSearchParams();
    if (params.limit!=null) q.set('limit', String(params.limit));
    if (params.offset!=null) q.set('offset', String(params.offset));
    return req(`/feed?${q.toString()}`);
  },
  catchById: (id:number) => req(`/catch/${id}`),
  addComment: (id:number, text:string, parent_id?:number|null) =>
    req(`/catch/${id}/comments`, { method:'POST', body: JSON.stringify({ text, parent_id: parent_id ?? null }) }),

  weather: (lat:number,lng:number, dt?:number) => {
    const q = new URLSearchParams({ lat:String(lat), lng:String(lng) });
    if (dt) q.set('dt', String(dt));
    return req(`/weather?${q.toString()}`);
  }
}
TS

########################################
# FRONTEND: Реальная карта (MapView.tsx) на react-leaflet
########################################
cat > "$STAGE/frontend/src/components/MapView.tsx" <<'TSX'
import React, { useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// фиксим иконки leaflet (без webpack loaders)
const icon = new L.Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  shadowSize: [41, 41],
  shadowAnchor: [12, 41],
});

function FitBounds({ bbox }: { bbox?: [number,number,number,number] }) {
  const map = useMap();
  useEffect(()=>{
    if (!bbox) return;
    const [[minLat,minLng],[maxLat,maxLng]] = [[bbox[1],bbox[0]],[bbox[3],bbox[2]]];
    map.fitBounds([[minLat,minLng],[maxLat,maxLng]], { padding:[24,24] });
  },[bbox]);
  return null;
}

type Point = {
  id:number; title:string; lat:number; lng:number; category?:string;
};
export default function MapView({
  points, center=[55.751244,37.618423], zoom=11, bbox
}:{ points:Point[]; center?:[number,number]; zoom?:number; bbox?:[number,number,number,number]}) {
  return (
    <div className="relative w-full h-full">
      <MapContainer
        center={center}
        zoom={zoom}
        className="w-full h-full rounded-2xl overflow-hidden"
        zoomControl={false}
      >
        <TileLayer
          attribution='&copy; CARTO & OpenStreetMap'
          url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
        />
        {points.map(p=>(
          <Marker key={p.id} position={[p.lat, p.lng]} icon={icon}>
            <Popup>
              <div className="text-sm">
                <div className="font-semibold">{p.title || 'Точка'}</div>
                {p.category && <div className="text-xs text-gray-500 mt-1">Категория: {p.category}</div>}
              </div>
            </Popup>
          </Marker>
        ))}
        <FitBounds bbox={bbox}/>
      </MapContainer>
    </div>
  );
}
TSX

########################################
# FRONTEND: Шапка с кликом на "Погода"
########################################
cat > "$STAGE/frontend/src/components/Header.tsx" <<'TSX'
import React from 'react';

export default function Header({ onLogoClick }:{ onLogoClick?:()=>void }) {
  return (
    <div className="fixed top-0 left-0 right-0 z-40">
      <div className="mx-auto max-w-screen-sm px-4 pt-3">
        <div className="backdrop-blur-xl bg-white/60 border border-white/40 rounded-2xl shadow-sm px-3 py-2 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <button onClick={onLogoClick} className="font-semibold text-gray-900">FishTrack Pro</button>
            <span className="text-xs px-2 py-1 rounded-full bg-gradient-to-r from-pink-400 to-fuchsia-500 text-white">beta</span>
          </div>
          <div className="flex items-center gap-4">
            <button
              className="text-sm text-gray-700 hover:text-gray-900"
              onClick={() => { window.location.hash = '#/weather'; }}
              aria-label="Открыть погоду"
              title="Погода"
            >
              ☁️ Погода
            </button>
            <button
              className="text-sm text-gray-700 hover:text-gray-900"
              onClick={() => { window.location.hash = '#/alerts'; }}
              aria-label="Уведомления"
              title="Уведомления"
            >
              🔔
            </button>
            <button
              className="text-sm text-gray-700 hover:text-gray-900"
              onClick={() => { window.location.hash = '#/profile'; }}
              aria-label="Профиль"
              title="Профиль"
            >
              🧑‍✈️
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
TSX

########################################
# FRONTEND: WeatherScreen.tsx — вывод температуры/ветра
########################################
cat > "$STAGE/frontend/src/screens/WeatherScreen.tsx" <<'TSX'
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
TSX

########################################
# FRONTEND: MapScreen.tsx (встраиваем реальную карту)
########################################
cat > "$STAGE/frontend/src/screens/MapScreen.tsx" <<'TSX'
import React, { useEffect, useMemo, useState } from 'react';
import { api } from '../lib/api';
import MapView from '../components/MapView';

type Point = { id:number; title:string; lat:number; lng:number; category?:string; };

export default function MapScreen(){
  const [points, setPoints] = useState<Point[]>([]);
  const [bbox, setBbox] = useState<[number,number,number,number] | undefined>(undefined);
  const [filter, setFilter] = useState<string|undefined>(undefined);

  useEffect(()=>{
    // Пример bbox для Москвы (если нет гео)
    const fallbackBbox:[number,number,number,number] = [37.2,55.5,37.9,55.95];
    const load = async ()=>{
      const params:any = { limit: 500, bbox: (bbox||fallbackBbox).join(',') };
      if (filter) params.filter = filter;
      const j = await api.points(params);
      setPoints(j.items || []);
    };
    load().catch(console.error);
  },[bbox, filter]);

  // UI для фильтров (минимально)
  const filters = useMemo(()=>[
    {key:undefined, title:'Все'},
    {key:'spot', title:'Споты'},
    {key:'shop', title:'Магазины'},
    {key:'slip', title:'Слипы'},
    {key:'camp', title:'Кемпинги'},
    {key:'catch', title:'Уловы'},
  ],[]);

  return (
    <div className="w-full h-full pt-16 pb-16">
      <div className="absolute top-16 left-0 right-0 z-30 px-4">
        <div className="overflow-x-auto no-scrollbar">
          <div className="inline-flex gap-2 backdrop-blur-xl bg-white/60 border border-white/40 rounded-2xl p-2">
            {filters.map(f=>(
              <button
                key={String(f.key)}
                onClick={()=>setFilter(f.key as any)}
                className={`px-3 py-1 rounded-xl text-sm ${filter===f.key ? 'bg-gradient-to-r from-pink-500 to-fuchsia-600 text-white' : 'bg-white/70 text-gray-800 border border-white/60'}`}
              >
                {f.title}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="absolute inset-0 top-16 bottom-16 z-10">
        <MapView points={points} bbox={bbox}/>
      </div>
    </div>
  );
}
TSX

########################################
# FRONTEND: Простой App header + маршрутизация по hash
########################################
cat > "$STAGE/frontend/src/App.tsx" <<'TSX'
import React, { useEffect, useState } from 'react';
import Header from './components/Header';
import MapScreen from './screens/MapScreen';
import WeatherScreen from './screens/WeatherScreen';

function useHash(): string {
  const [h,setH]=useState(window.location.hash||'#/map');
  useEffect(()=>{
    const on = ()=>setH(window.location.hash||'#/map');
    window.addEventListener('hashchange',on);
    return ()=>window.removeEventListener('hashchange',on);
  },[]);
  return h;
}

export default function App(){
  const hash = useHash();
  const route = hash.replace(/^#\//,'') || 'map';

  return (
    <div className="w-full h-screen relative bg-gray-50">
      <Header />
      {route==='map' && <MapScreen/>}
      {route==='weather' && <WeatherScreen/>}
      {route!=='map' && route!=='weather' && (
        <div className="pt-20 px-4 text-gray-500">Страница в разработке</div>
      )}
    </div>
  );
}
TSX

########################################
# FRONTEND: Глобальные стили (фикс z-index карты)
########################################
cat > "$STAGE/frontend/src/styles/global.css" <<'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* импортируем до пользовательских правил — чтобы не ругался postcss */
@import "leaflet/dist/leaflet.css";

/* UI над картой */
.leaflet-container { z-index: 0; }
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
CSS

########################################
# FRONTEND: index.tsx (точка входа)
########################################
cat > "$STAGE/frontend/src/index.tsx" <<'TSX'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './styles/global.css';

const el = document.getElementById('root');
if (el) {
  const root = createRoot(el);
  root.render(<App />);
}
TSX

########################################
# FRONTEND: public/index.html (минимальный шаблон)
########################################
cat > "$STAGE/frontend/public/index.html" <<'HTML'
<!doctype html>
<html lang="ru">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no" />
    <title>FishTrack Pro</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/index.tsx"></script>
  </body>
</html>
HTML

########################################
# Готовим zip
########################################
rm -f "$ZIP_NAME"
( cd "$STAGE" && zip -qr "../$ZIP_NAME" . )
echo "OK -> $ZIP_NAME"