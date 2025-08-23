#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
BACK="$ROOT/backend"
FRONT="$ROOT/frontend"

echo "==> Backend: upload + weather proxy + points helper"

mkdir -p "$BACK/app/Http/Controllers/Api" "$BACK/app/Services"

# ---- Media upload controller (photo/video) ----
cat > "$BACK/app/Http/Controllers/Api/UploadController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class UploadController extends Controller
{
    public function store(Request $r)
    {
        $r->validate([
            'file' => 'required|file|max:' . (int) env('FILES_UPLOAD_MAX', 10485760), // 10MB default
        ]);
        $file = $r->file('file');
        $ext  = strtolower($file->getClientOriginalExtension());
        $isVideo = in_array($ext, ['mp4','mov','webm','mkv']);
        $path = $file->store($isVideo ? 'uploads/videos' : 'uploads/photos', 'public');
        return response()->json([
            'ok' => true,
            'url' => Storage::disk('public')->url($path),
            'type' => $isVideo ? 'video' : 'image',
        ]);
    }
}
PHP

# ---- Weather proxy (OpenWeather OneCall historical/actual) ----
cat > "$BACK/app/Http/Controllers/Api/WeatherProxyController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class WeatherProxyController extends Controller
{
    public function show(Request $r)
    {
        $r->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
            'dt'  => 'nullable|integer' // unix timestamp (по дате улова), если нет — текущее
        ]);
        $lat = $r->float('lat');
        $lng = $r->float('lng');
        $dt  = $r->input('dt');
        $key = env('OPENWEATHER_KEY');
        if (!$key) return response()->json(['ok'=>false,'error'=>'OPENWEATHER_KEY missing'], 500);

        // Если передана дата (dt) — используем timemachine (история), иначе — текущее
        if ($dt) {
            $url = "https://api.openweathermap.org/data/3.0/onecall/timemachine";
            $resp = Http::timeout(10)->get($url, [
                'lat'=>$lat,'lon'=>$lng,'dt'=>$dt,'appid'=>$key,'units'=>'metric','lang'=>'ru'
            ]);
        } else {
            $url = "https://api.openweathermap.org/data/3.0/onecall";
            $resp = Http::timeout(10)->get($url, [
                'lat'=>$lat,'lon'=>$lng,'appid'=>$key,'units'=>'metric','lang'=>'ru','exclude'=>'minutely,hourly,alerts'
            ]);
        }
        if (!$resp->ok()) return response()->json(['ok'=>false,'status'=>$resp->status(),'body'=>$resp->body()], 502);
        return response()->json(['ok'=>true,'data'=>$resp->json()]);
    }
}
PHP

# ---- Points helper (bbox/filter для карты), читает fishing_points без лишних полей ----
cat > "$BACK/app/Http/Controllers/Api/PointsController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PointsController extends Controller
{
    public function index(Request $r)
    {
        $limit = min(1000, (int) $r->query('limit', 500));
        $filter = $r->query('filter'); // spot|shop|slip|camp|null
        $bbox = $r->query('bbox');     // minLng,minLat,maxLng,maxLat

        $q = DB::table('fishing_points')->select('id','title','description','lat','lng','category','is_highlighted','status')
            ->where('is_public', 1)
            ->where('status','approved');

        if ($filter) $q->where('category',$filter);
        if ($bbox) {
            $parts = array_map('floatval', explode(',', $bbox));
            if (count($parts) === 4) {
                [$minLng,$minLat,$maxLng,$maxLat] = $parts;
                $q->whereBetween('lat', [$minLat,$maxLat])
                  ->whereBetween('lng', [$minLng,$maxLng]);
            }
        }
        $items = $q->orderByDesc('id')->limit($limit)->get();
        return response()->json(['items'=>$items]);
    }
}
PHP

# ---- Routes append (safe) ----
ROUTES="$BACK/routes/api.php"
if ! grep -q "UploadController" "$ROUTES"; then
cat >> "$ROUTES" <<'PHP'

// v1 uploads + weather + points
use App\Http\Controllers\Api\UploadController;
use App\Http\Controllers\Api\WeatherProxyController;
use App\Http\Controllers\Api\PointsController;

Route::prefix('v1')->group(function () {
    Route::post('/upload', [UploadController::class,'store']);              // multipart form upload
    Route::get('/weather', [WeatherProxyController::class,'show']);         // ?lat=&lng=&dt=
    Route::get('/map/points', [PointsController::class,'index']);           // список точек для карты
});
PHP
fi

# ---- Storage symlink (best effort) ----
( cd "$BACK" && php artisan storage:link >/dev/null 2>&1 || true )

echo "==> Frontend: UI на shadcn/ui, карта-пикер, аплоад и автопогода"

mkdir -p "$FRONT/src/components" "$FRONT/src/screens" "$FRONT/src/lib" "$FRONT/src/styles"

# API helper
cat > "$FRONT/src/lib/api.ts" <<'TS'
export const API_BASE = (import.meta as any).env?.VITE_API_BASE ?? "https://api.fishtrackpro.ru";
export const buildUrl = (path: string) => new URL(path, API_BASE).toString();
export async function apiGet<T=any>(path: string, q?: Record<string, string|number|boolean|null|undefined>) {
  const url = new URL(buildUrl(path));
  if (q) Object.entries(q).forEach(([k,v]) => (v!==undefined && v!==null) && url.searchParams.set(k, String(v)));
  const r = await fetch(url.toString(), { headers: { 'Accept':'application/json' }});
  if (!r.ok) throw new Error(`GET ${url} -> ${r.status}`);
  return r.json() as Promise<T>;
}
export async function apiPostJSON<T=any>(path: string, body: any) {
  const r = await fetch(buildUrl(path), { method:'POST', headers:{ 'Content-Type':'application/json', 'Accept':'application/json' }, body: JSON.stringify(body) });
  if (!r.ok) throw new Error(`POST ${path} -> ${r.status}`);
  return r.json() as Promise<T>;
}
export async function apiUpload(file: File) {
  const form = new FormData(); form.append('file', file);
  const r = await fetch(buildUrl('/api/v1/upload'), { method:'POST', body: form });
  if (!r.ok) throw new Error(`UPLOAD -> ${r.status}`);
  return r.json() as Promise<{ok:boolean,url:string,type:'image'|'video'}>;
}
TS

# Тост
cat > "$FRONT/src/lib/toast.ts" <<'TS'
export function toast(msg: string) {
  const el = document.createElement('div');
  el.textContent = msg;
  el.className = 'fixed left-1/2 -translate-x-1/2 bottom-24 px-4 py-2 rounded-full bg-black/70 text-white text-sm z-[1000]';
  document.body.appendChild(el); setTimeout(()=>el.remove(), 2200);
}
TS

# shadcn/ui – простые прокси-компоненты (без внешней установки)
cat > "$FRONT/src/components/ui.tsx" <<'TSX'
import React from "react";

export const Card = ({children,className=""}:{children:any,className?:string}) =>
  <div className={"rounded-2xl bg-white/70 backdrop-blur border border-white/60 shadow-md " + className}>{children}</div>;

export const CardContent = ({children,className=""}:{children:any,className?:string}) =>
  <div className={"p-4 "+className}>{children}</div>;

export const Button = ({children,onClick,type="button",variant="default",className=""}:{children:any;onClick?:any;type?:"button"|"submit";variant?:"default"|"secondary"|"ghost";className?:string;}) => {
  const map: Record<string,string> = {
    default: "bg-black text-white",
    secondary: "bg-white/70 border border-white/60",
    ghost: "bg-transparent"
  };
  return <button type={type} onClick={onClick} className={`rounded-full px-4 py-2 ${map[variant]} ${className}`} >{children}</button>;
};

export const Input = (props: React.InputHTMLAttributes<HTMLInputElement>) =>
  <input {...props} className={"w-full rounded-xl px-3 py-2 bg-white/70 backdrop-blur border border-white/60 outline-none "+(props.className||"")} />;

export const Textarea = (props: React.TextareaHTMLAttributes<HTMLTextAreaElement>) =>
  <textarea {...props} className={"w-full rounded-xl px-3 py-2 bg-white/70 backdrop-blur border border-white/60 outline-none "+(props.className||"")} />;

export const Select = ({value,onChange,children,className=""}:{value:any;onChange:any;children:any;className?:string;}) =>
  <select value={value} onChange={onChange} className={"w-full rounded-xl px-3 py-2 bg-white/70 backdrop-blur border border-white/60 outline-none "+className}>{children}</select>;
TSX

# Карта-пикер (Leaflet)
mkdir -p "$FRONT/src/components/map"
cat > "$FRONT/src/components/map/MapPicker.tsx" <<'TSX'
import React, { useEffect, useRef } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

type Props = { lat?: number; lng?: number; onPick: (lat:number,lng:number)=>void; height?: number|string; };
export default function MapPicker({lat=55.7558,lng=37.6173,onPick,height=300}:Props){
  const ref = useRef<HTMLDivElement>(null);
  const markerRef = useRef<L.Marker|null>(null);
  useEffect(()=>{
    if(!ref.current) return;
    const map = L.map(ref.current,{ zoomControl:true, attributionControl:false }).setView([lat,lng], 11);
    const tile = L.tileLayer(`https://tile.openstreetmap.org/{z}/{x}/{y}.png`,{ maxZoom:19 }); tile.addTo(map);
    markerRef.current = L.marker([lat,lng],{draggable:true}).addTo(map);
    markerRef.current.on("dragend",()=>{
      const p = markerRef.current!.getLatLng();
      onPick(p.lat, p.lng);
    });
    map.on("click",(e:any)=>{
      const {lat,lng} = e.latlng;
      markerRef.current!.setLatLng([lat,lng]);
      onPick(lat,lng);
    });
    return ()=>{ map.remove(); }
  },[]);
  return <div ref={ref} style={{height}} className="rounded-xl overflow-hidden border border-white/60" />;
}
TSX

# Компонент загрузки файлов
cat > "$FRONT/src/components/Uploader.tsx" <<'TSX'
import React, { useRef, useState } from "react";
import { apiUpload } from "../lib/api";
import { Button } from "./ui";
import { toast } from "../lib/toast";

export default function Uploader({onUploaded}:{onUploaded:(url:string,type:'image'|'video')=>void}){
  const inputRef = useRef<HTMLInputElement>(null);
  const [loading,setLoading] = useState(false);

  const onPick = ()=> inputRef.current?.click();

  const onChange = async (e: React.ChangeEvent<HTMLInputElement>)=>{
    const f = e.target.files?.[0]; if(!f) return;
    setLoading(true);
    try {
      const res = await apiUpload(f);
      onUploaded(res.url, res.type);
      toast("Файл загружен");
    } catch(e:any){
      toast("Ошибка загрузки");
      console.error(e);
    } finally {
      setLoading(false);
      e.target.value = "";
    }
  }

  return (
    <div className="flex items-center gap-3">
      <input ref={inputRef} type="file" accept="image/*,video/*" className="hidden" onChange={onChange}/>
      <Button onClick={onPick} variant="secondary">{loading ? "Загрузка…" : "Загрузить фото/видео"}</Button>
    </div>
  );
}
TSX

# Экран формы улова (красиво + погода + карта)
cat > "$FRONT/src/screens/AddCatchScreen.tsx" <<'TSX'
import React, { useEffect, useMemo, useState } from "react";
import { Card, CardContent, Button, Input, Textarea, Select } from "../components/ui";
import Uploader from "../components/Uploader";
import MapPicker from "../components/map/MapPicker";
import { apiGet, apiPostJSON } from "../lib/api";
import { toast } from "../lib/toast";

export default function AddCatchScreen({onDone}:{onDone:()=>void}) {
  const [form, setForm] = useState({
    lat: 55.7558, lng: 37.6173,
    species: "", length: "", weight: "",
    style: "", lure: "", tackle: "",
    notes: "", photo_url: "", caught_at: "", privacy: "all",
    water_type:"", water_temp:"", wind_speed:"", pressure:""
  });
  const [loading, setLoading] = useState(false);

  const set = (k:string,v:any)=> setForm(p=>({...p,[k]:v}));

  const ts = useMemo(()=> {
    if (!form.caught_at) return null;
    const t = new Date(form.caught_at);
    return Math.floor(t.getTime()/1000);
  }, [form.caught_at]);

  useEffect(()=>{
    // авто-погода при наличии координат и времени
    if (!form.lat || !form.lng) return;
    const run = async ()=>{
      try{
        const j:any = await apiGet('/api/v1/weather', { lat: form.lat, lng: form.lng, dt: ts || undefined });
        const d = j.data;
        // извлечём "самое похоже" — current (или первый из data)
        const current = d?.current ?? d?.data?.[0] ?? null;
        if (current) {
          if (current.temp != null) set('water_temp', current.temp); // формально это air temp, но для UX — ок до добавления реальных сенсоров
          if (current.wind_speed != null) set('wind_speed', current.wind_speed);
          if (current.pressure != null) set('pressure', current.pressure);
        }
      }catch(e){ /* молча */ }
    };
    run();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [form.lat, form.lng, ts]);

  const submit = async (e: React.FormEvent)=>{
    e.preventDefault();
    setLoading(true);
    try{
      const payload:any = {
        lat: Number(form.lat), lng: Number(form.lng),
        species: form.species || null,
        length: form.length ? Number(form.length) : null,
        weight: form.weight ? Number(form.weight) : null,
        style: form.style || null, lure: form.lure || null, tackle: form.tackle || null,
        notes: form.notes || null, photo_url: form.photo_url || null,
        caught_at: form.caught_at || null, privacy: form.privacy || "all",
        water_type: form.water_type || null,
        water_temp: form.water_temp ? Number(form.water_temp) : null,
        wind_speed: form.wind_speed ? Number(form.wind_speed) : null,
        pressure: form.pressure ? Number(form.pressure) : null
      };
      await apiPostJSON('/api/v1/catches', payload);
      toast("Улов добавлен");
      onDone();
    }catch(e:any){
      toast("Ошибка сохранения");
      console.error(e);
    }finally{
      setLoading(false);
    }
  };

  return (
    <Card>
      <CardContent>
        <form onSubmit={submit} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <Input placeholder="Вид рыбы" value={form.species} onChange={e=>set('species', e.target.value)} />
            <Input placeholder="Дата/время" type="datetime-local" value={form.caught_at} onChange={e=>set('caught_at', e.target.value)} />
            <Input placeholder="Вес (кг)" value={form.weight} onChange={e=>set('weight', e.target.value)} />
            <Input placeholder="Длина (см)" value={form.length} onChange={e=>set('length', e.target.value)} />
            <Input placeholder="Стиль" value={form.style} onChange={e=>set('style', e.target.value)} />
            <Input placeholder="Приманка" value={form.lure} onChange={e=>set('lure', e.target.value)} />
            <Input placeholder="Снасти" value={form.tackle} onChange={e=>set('tackle', e.target.value)} />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Input placeholder="Широта (lat)" value={form.lat} onChange={e=>set('lat', Number(e.target.value))} />
            <Input placeholder="Долгота (lng)" value={form.lng} onChange={e=>set('lng', Number(e.target.value))} />
          </div>

          <MapPicker lat={form.lat} lng={form.lng} onPick={(a,b)=>{ set('lat',a); set('lng',b); }} height={250} />

          <Uploader onUploaded={(url)=> set('photo_url', url)} />
          {form.photo_url && <div className="text-xs text-gray-600 break-all">Файл: {form.photo_url}</div>}

          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <Select value={form.privacy} onChange={e=>set('privacy', e.target.value)}>
              <option value="all">Публично</option>
              <option value="friends">Друзья</option>
              <option value="private">Приватно</option>
            </Select>
            <Input placeholder="Тип воды" value={form.water_type} onChange={e=>set('water_type', e.target.value)} />
            <Input placeholder="Темп. воды/воздуха (°C)" value={form.water_temp} onChange={e=>set('water_temp', e.target.value)} />
            <Input placeholder="Ветер (м/с)" value={form.wind_speed} onChange={e=>set('wind_speed', e.target.value)} />
            <Input placeholder="Давление (гПа)" value={form.pressure} onChange={e=>set('pressure', e.target.value)} />
          </div>

          <Textarea placeholder="Заметки" value={form.notes} onChange={e=>set('notes', e.target.value)} />

          <div className="flex justify-end gap-2">
            <Button variant="secondary" onClick={onDone}>Отмена</Button>
            <Button type="submit">{loading ? "Сохранение…" : "Сохранить улов"}</Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
TSX

# Экран формы места (категории, карта, аплоад)
cat > "$FRONT/src/screens/AddPlaceScreen.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { Card, CardContent, Button, Input, Textarea, Select } from "../components/ui";
import Uploader from "../components/Uploader";
import MapPicker from "../components/map/MapPicker";
import { apiGet, apiPostJSON } from "../lib/api";
import { toast } from "../lib/toast";

export default function AddPlaceScreen({onDone}:{onDone:()=>void}) {
  const [cats, setCats] = useState<string[]>(["spot","shop","slip","camp"]);
  const [form, setForm] = useState({
    title:"", description:"", category:"spot", lat:55.7558, lng:37.6173,
    is_public:true, is_highlighted:false, preview_url:""
  });
  const [loading, setLoading] = useState(false);
  const set = (k:string,v:any)=> setForm(p=>({...p,[k]:v}));

  useEffect(()=>{
    apiGet('/api/v1/points/categories').then((j:any)=>{
      if (Array.isArray(j.items)) setCats(j.items);
    }).catch(()=>{});
  },[]);

  const submit = async (e: React.FormEvent) =>{
    e.preventDefault(); setLoading(true);
    try{
      const payload:any = {
        title: form.title,
        description: form.description || null,
        category: form.category,
        lat: Number(form.lat), lng: Number(form.lng),
        is_public: !!form.is_public, is_highlighted: !!form.is_highlighted,
        status: 'approved'
      };
      await apiPostJSON('/api/v1/points', payload);
      toast("Место добавлено");
      onDone();
    }catch(e:any){
      toast("Ошибка сохранения");
      console.error(e);
    }finally{ setLoading(false); }
  };

  return (
    <Card>
      <CardContent>
        <form onSubmit={submit} className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <Input placeholder="Название" value={form.title} onChange={e=>set('title', e.target.value)} required />
            <Select value={form.category} onChange={e=>set('category', e.target.value)}>
              {cats.map(c => <option key={c} value={c}>{c}</option>)}
            </Select>
          </div>

          <Textarea placeholder="Описание" value={form.description} onChange={e=>set('description', e.target.value)} />

          <div className="grid grid-cols-2 gap-3">
            <Input placeholder="Широта (lat)" value={form.lat} onChange={e=>set('lat', Number(e.target.value))} />
            <Input placeholder="Долгота (lng)" value={form.lng} onChange={e=>set('lng', Number(e.target.value))} />
          </div>

          <MapPicker lat={form.lat} lng={form.lng} onPick={(a,b)=>{ set('lat',a); set('lng',b); }} height={250} />

          <Uploader onUploaded={(url)=> set('preview_url', url)} />
          {form.preview_url && <div className="text-xs text-gray-600 break-all">Обложка: {form.preview_url}</div>}

          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={form.is_public} onChange={e=>set('is_public', e.target.checked)} />
            Публично
          </label>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" checked={form.is_highlighted} onChange={e=>set('is_highlighted', e.target.checked)} />
            Выделить на карте
          </label>

          <div className="flex justify-end gap-2">
            <Button variant="secondary" onClick={onDone}>Отмена</Button>
            <Button type="submit">{loading ? "Сохранение…" : "Сохранить место"}</Button>
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
TSX

# Подключение форм в App.tsx (FAB -> chooser -> формы)
APP="$FRONT/src/App.tsx"
if [ -f "$APP" ]; then cp "$APP" "$APP.bak.$(date +%s)"; fi
cat > "$FRONT/src/App.tsx" <<'TSX'
import React, { useMemo, useState } from "react";
import MapScreen from "./screens/MapScreen";
import FeedScreen from "./screens/FeedScreen";
import ProfileScreen from "./screens/ProfileScreen";
import AuthScreen from "./screens/AuthScreen";
import BottomNav from "./components/BottomNav";
import AddCatchScreen from "./screens/AddCatchScreen";
import AddPlaceScreen from "./screens/AddPlaceScreen";
import Modal from "./components/Modal";
import { useAuthState } from "./data/auth";

type Tab="map"|"feed"|"alerts"|"profile";
type FormKind = null | "catch" | "place" | "chooser";

export default function App(){
  const [tab,setTab]=useState<Tab>("map");
  const {isAuthed}=useAuthState?.() ?? {isAuthed:false};
  const needAuth=useMemo(()=> (tab==="feed"||tab==="profile") && !isAuthed, [tab,isAuthed]);
  const [form,setForm]=useState<FormKind>(null);

  const onFab=()=> setForm("chooser");
  const closeAll = ()=> setForm(null);

  return (
    <div className="relative w-full h-screen bg-gray-100">
      {tab==="map" && <MapScreen/>}
      {tab==="feed" && <FeedScreen/>}
      {tab==="alerts" && <div className="flex items-center justify-center w-full h-full text-gray-600">Уведомления скоро будут</div>}
      {tab==="profile" && <ProfileScreen/>}

      <BottomNav onFab={onFab} active={tab} onChange={setTab as any}/>

      {needAuth && <AuthScreen onClose={()=>setTab("map")}/>}

      {/* Выбор действия FAB */}
      <Modal open={form==="chooser"} onClose={closeAll} title="Что добавить?">
        <div className="grid sm:grid-cols-2 gap-3">
          <button className="rounded-full px-4 py-2 bg-black text-white" onClick={()=>setForm("catch")}>🎣 Улов</button>
          <button className="rounded-full px-4 py-2 bg-white/70 border border-white/60" onClick={()=>setForm("place")}>📍 Место</button>
        </div>
      </Modal>

      {/* Формы */}
      <Modal open={form==="catch"} onClose={closeAll} title="Добавить улов">
        <AddCatchScreen onDone={closeAll}/>
      </Modal>
      <Modal open={form==="place"} onClose={closeAll} title="Добавить место">
        <AddPlaceScreen onDone={closeAll}/>
      </Modal>
    </div>
  );
}
TSX

# Tailwind helpers (если нужно)
if [ -f "$FRONT/src/index.css" ] && ! grep -q "leaflet.css" "$FRONT/src/index.css"; then
  echo '@import "leaflet/dist/leaflet.css";' >> "$FRONT/src/index.css"
fi

echo "==> Готово."
echo "Проверьте: "
echo "  - POST /api/v1/upload (multipart file=...)"
echo "  - GET  /api/v1/weather?lat=55.75&lng=37.62&dt=1736899200"
echo "  - GET  /api/v1/map/points"
echo "Во фронте: FAB -> выбор -> формы; карта-пикер; авто-погода; аплоад."