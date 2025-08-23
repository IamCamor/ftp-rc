#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
BACK="$ROOT/backend"
FRONT="$ROOT/frontend"

echo "==> Backend: контроллеры Upload/Weather/Points/Feed/Catch/Comments/Likes/Follow и роуты"

mkdir -p "$BACK/app/Http/Controllers/Api"

# ---------------- UploadController ----------------
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
        $r->validate(['file'=>'required|file|max:'.(int)env('FILES_UPLOAD_MAX',10485760)]);
        $f = $r->file('file');
        $ext = strtolower($f->getClientOriginalExtension());
        $isVideo = in_array($ext,['mp4','mov','webm','mkv']);
        $path = $f->store($isVideo?'uploads/videos':'uploads/photos','public');
        return response()->json([
            'ok'=>true,
            'url'=>Storage::disk('public')->url($path),
            'type'=>$isVideo?'video':'image'
        ]);
    }
}
PHP

# ---------------- WeatherProxyController ----------------
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
        $r->validate(['lat'=>'required|numeric','lng'=>'required|numeric','dt'=>'nullable|integer']);
        $lat=$r->float('lat'); $lng=$r->float('lng'); $dt=$r->input('dt');
        $key = env('OPENWEATHER_KEY');
        if(!$key) return response()->json(['ok'=>false,'error'=>'OPENWEATHER_KEY missing'],500);

        if($dt){
            $url="https://api.openweathermap.org/data/3.0/onecall/timemachine";
            $resp=Http::timeout(10)->get($url,['lat'=>$lat,'lon'=>$lng,'dt'=>$dt,'appid'=>$key,'units'=>'metric','lang'=>'ru']);
        }else{
            $url="https://api.openweathermap.org/data/3.0/onecall";
            $resp=Http::timeout(10)->get($url,['lat'=>$lat,'lon'=>$lng,'appid'=>$key,'units'=>'metric','lang'=>'ru','exclude'=>'minutely,hourly,alerts']);
        }
        if(!$resp->ok()) return response()->json(['ok'=>false,'status'=>$resp->status(),'body'=>$resp->body()],502);
        return response()->json(['ok'=>true,'data'=>$resp->json()]);
    }
}
PHP

# ---------------- PointsController (index + store + categories) ----------------
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
        $limit = min(1000,(int)$r->query('limit',500));
        $filter = $r->query('filter'); // spot|shop|slip|camp
        $bbox = $r->query('bbox');     // minLng,minLat,maxLng,maxLat

        $q = DB::table('fishing_points')
            ->select('id','title','description','lat','lng','category','is_highlighted','status')
            ->where('is_public',1)->where('status','approved');

        if($filter) $q->where('category',$filter);
        if($bbox){
            $p = array_map('floatval', explode(',',$bbox));
            if(count($p)===4){ [$minLng,$minLat,$maxLng,$maxLat]=$p;
                $q->whereBetween('lat',[$minLat,$maxLat])->whereBetween('lng',[$minLng,$maxLng]);
            }
        }
        return response()->json(['items'=>$q->orderByDesc('id')->limit($limit)->get()]);
    }

    public function categories()
    {
        return response()->json(['items'=>['spot','shop','slip','camp']]);
    }

    public function store(Request $r)
    {
        // пишем только существующие поля
        $data = $r->validate([
            'title'=>'required|string|min:2',
            'description'=>'nullable|string',
            'category'=>'required|in:spot,shop,slip,camp',
            'lat'=>'required|numeric',
            'lng'=>'required|numeric',
            'is_public'=>'boolean',
            'is_highlighted'=>'boolean',
            'status'=>'nullable|in:approved,pending,rejected'
        ]);
        $data['is_public'] = (int)($data['is_public'] ?? 1);
        $data['is_highlighted'] = (int)($data['is_highlighted'] ?? 0);
        $data['status'] = $data['status'] ?? 'approved';
        $id = DB::table('fishing_points')->insertGetId($data);
        $row = DB::table('fishing_points')->where('id',$id)->first();
        return response()->json($row,201);
    }
}
PHP

# ---------------- FeedController (лента) ----------------
cat > "$BACK/app/Http/Controllers/Api/FeedController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FeedController extends Controller
{
    public function index(Request $r)
    {
        $limit = min(50,(int)$r->query('limit',20));
        $offset = max(0,(int)$r->query('offset',0));
        $species = $r->query('species');
        $userId = $r->query('user_id');
        $placeId = $r->query('place_id');

        $q = DB::table('catch_records AS cr')
            ->leftJoin('users AS u','u.id','=','cr.user_id')
            ->selectRaw("
                cr.id, cr.user_id, u.name AS user_name,
                COALESCE(u.avatar, u.photo_url, '') AS user_avatar,
                cr.lat, cr.lng, cr.species, cr.length, cr.weight,
                cr.style, cr.lure, cr.tackle, cr.notes, cr.photo_url,
                cr.caught_at, cr.created_at,
                (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count,
                (SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id=cr.id AND (cc.is_approved=1 OR cc.is_approved IS NULL)) AS comments_count
            ")
            ->where('cr.privacy','all');

        if($species) $q->where('cr.species','like','%'.$species.'%');
        if($userId) $q->where('cr.user_id',$userId);

        if($placeId){
            $place = DB::table('fishing_points')->where('id',(int)$placeId)->first();
            if($place){
                $lat0=$place->lat; $lng0=$place->lng; $km=2.0; // радиус ~2км
                $q->whereRaw(" (6371*ACOS( COS(RADIANS(?))*COS(RADIANS(cr.lat))*COS(RADIANS(cr.lng)-RADIANS(?)) + SIN(RADIANS(?))*SIN(RADIANS(cr.lat)) ) ) <= ? ",
                    [$lat0,$lng0,$lat0,$km]);
            }
        }

        // Новые сверху
        $q->orderByDesc('cr.created_at')->orderByDesc('cr.id');

        $items = $q->limit($limit)->offset($offset)->get();

        return response()->json([
            'items'=>$items,
            'next_offset'=>$offset + $items->count()
        ]);
    }
}
PHP

# ---------------- CatchController (деталь + создание + маркеры по виду) ----------------
cat > "$BACK/app/Http/Controllers/Api/CatchController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CatchController extends Controller
{
    public function show($id)
    {
        $row = DB::table('catch_records AS cr')
            ->leftJoin('users AS u','u.id','=','cr.user_id')
            ->selectRaw("
                cr.*, u.name AS user_name,
                COALESCE(u.avatar, u.photo_url, '') AS user_avatar,
                (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count,
                (SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id=cr.id AND (cc.is_approved=1 OR cc.is_approved IS NULL)) AS comments_count
            ")
            ->where('cr.id',(int)$id)->first();
        if(!$row) return response()->json(['message'=>'Not found'],404);

        $comments = DB::table('catch_comments AS c')
            ->leftJoin('users AS u','u.id','=','c.user_id')
            ->selectRaw("c.id,c.body,c.created_at, COALESCE(u.name,'Гость') AS user_name, COALESCE(u.avatar,u.photo_url,'') AS user_avatar")
            ->where('c.catch_id',(int)$id)
            ->where(function($w){ $w->where('c.is_approved',1)->orWhereNull('c.is_approved'); })
            ->orderBy('c.created_at','asc')->limit(100)->get();

        return response()->json(['item'=>$row,'comments'=>$comments]);
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'lat'=>'required|numeric','lng'=>'required|numeric',
            'species'=>'nullable|string','length'=>'nullable|numeric','weight'=>'nullable|numeric',
            'style'=>'nullable|string','lure'=>'nullable|string','tackle'=>'nullable|string',
            'notes'=>'nullable|string','photo_url'=>'nullable|string',
            'caught_at'=>'nullable|date','privacy'=>'nullable|in:all,friends,private',
            'water_type'=>'nullable|string','water_temp'=>'nullable|numeric','wind_speed'=>'nullable|numeric','pressure'=>'nullable|numeric'
        ]);
        $data['privacy'] = $data['privacy'] ?? 'all';
        $id = DB::table('catch_records')->insertGetId($data);
        return $this->show($id);
    }

    public function markers(Request $r)
    {
        $species = $r->query('species');
        $q = DB::table('catch_records')->select('id','lat','lng','species')->where('privacy','all');
        if($species) $q->where('species','like','%'.$species.'%');
        return response()->json(['items'=>$q->orderByDesc('id')->limit(1000)->get()]);
    }
}
PHP

# ---------------- CommentController ----------------
cat > "$BACK/app/Http/Controllers/Api/CommentController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CommentController extends Controller
{
    public function store(Request $r, $id)
    {
        $r->validate(['body'=>'required|string|min:1']);
        $userId = $r->user()->id ?? $r->input('user_id'); // временно допускаем user_id в теле
        if(!$userId) return response()->json(['message'=>'Unauthorized'],401);

        $cid = DB::table('catch_comments')->insertGetId([
            'catch_id'=>(int)$id, 'user_id'=>(int)$userId, 'body'=>$r->input('body'),
            'is_approved'=>1, 'created_at'=>now(), 'updated_at'=>now()
        ]);
        return response()->json(['ok'=>true,'comment_id'=>$cid]);
    }
}
PHP

# ---------------- LikeController (toggle) ----------------
cat > "$BACK/app/Http/Controllers/Api/LikeController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LikeController extends Controller
{
    public function toggle(Request $r, $id)
    {
        $userId = $r->user()->id ?? $r->input('user_id');
        if(!$userId) return response()->json(['message'=>'Unauthorized'],401);

        $exists = DB::table('catch_likes')->where(['catch_id'=>(int)$id,'user_id'=>(int)$userId])->first();
        if($exists){
            DB::table('catch_likes')->where('id',$exists->id)->delete();
            $liked=false;
        }else{
            DB::table('catch_likes')->insert(['catch_id'=>(int)$id,'user_id'=>(int)$userId,'created_at'=>now(),'updated_at'=>now()]);
            $liked=true;
        }
        $cnt = DB::table('catch_likes')->where('catch_id',(int)$id)->count();
        return response()->json(['ok'=>true,'liked'=>$liked,'likes_count'=>$cnt]);
    }
}
PHP

# ---------------- FollowController (toggle) ----------------
cat > "$BACK/app/Http/Controllers/Api/FollowController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FollowController extends Controller
{
    public function toggle(Request $r, $targetId)
    {
        $userId = $r->user()->id ?? $r->input('user_id');
        if(!$userId) return response()->json(['message'=>'Unauthorized'],401);
        if((int)$userId === (int)$targetId) return response()->json(['message'=>'Bad request'],400);

        $ex = DB::table('follows')->where(['follower_id'=>(int)$userId,'followed_id'=>(int)$targetId])->first();
        if($ex){
            DB::table('follows')->where('id',$ex->id)->delete();
            $following=false;
        }else{
            DB::table('follows')->insert(['follower_id'=>(int)$userId,'followed_id'=>(int)$targetId,'created_at'=>now(),'updated_at'=>now()]);
            $following=true;
        }
        return response()->json(['ok'=>true,'following'=>$following]);
    }
}
PHP

# ---------------- Обновление routes/api.php ----------------
ROUTES="$BACK/routes/api.php"
cp "$ROUTES" "$ROUTES.bak.$(date +%s)" || true
cat > "$ROUTES" <<'PHP'
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\UploadController;
use App\Http\Controllers\Api\WeatherProxyController;
use App\Http\Controllers\Api\PointsController;
use App\Http\Controllers\Api\FeedController;
use App\Http\Controllers\Api\CatchController;
use App\Http\Controllers\Api\CommentController;
use App\Http\Controllers\Api\LikeController;
use App\Http\Controllers\Api\FollowController;

Route::get('/health', fn()=>response()->json(['ok'=>true,'ts'=>now()]));

Route::prefix('v1')->group(function () {
    // карты/точки
    Route::get('/map/points',[PointsController::class,'index']);
    Route::get('/points/categories',[PointsController::class,'categories']);
    Route::post('/points',[PointsController::class,'store']);

    // загрузки/погода
    Route::post('/upload',[UploadController::class,'store']);
    Route::get('/weather',[WeatherProxyController::class,'show']);

    // лента/уловы
    Route::get('/feed',[FeedController::class,'index']);
    Route::get('/catch/{id}',[CatchController::class,'show']);
    Route::post('/catches',[CatchController::class,'store']);
    Route::get('/catches/markers',[CatchController::class,'markers']);

    // комменты/лайки/фоллоу
    Route::post('/catch/{id}/comments',[CommentController::class,'store']);
    Route::post('/catch/{id}/like',[LikeController::class,'toggle']);
    Route::post('/follow/{userId}',[FollowController::class,'toggle']);
});
PHP

# симлинк стораджа
( cd "$BACK" && php artisan storage:link >/dev/null 2>&1 || true )

echo "==> Frontend: отдельные страницы, крупная карта, лента (новые сверху), деталь улова, переходы, маркеры по виду"

mkdir -p "$FRONT/src/lib" "$FRONT/src/screens" "$FRONT/src/components" "$FRONT/src/components/map"

# -------- API helper --------
cat > "$FRONT/src/lib/api.ts" <<'TS'
export const API_BASE = (import.meta as any).env?.VITE_API_BASE ?? "https://api.fishtrackpro.ru";

const url = (p:string)=> new URL(p, API_BASE).toString();

export async function getJSON<T=any>(p:string, q?:Record<string, any>) {
  const u = new URL(url(p)); if(q) Object.entries(q).forEach(([k,v])=> (v!==undefined&&v!==null) && u.searchParams.set(k,String(v)));
  const r = await fetch(u.toString(),{headers:{'Accept':'application/json'}});
  if(!r.ok) throw new Error(`${r.status}`);
  return r.json() as Promise<T>;
}
export async function postJSON<T=any>(p:string, body:any){
  const r=await fetch(url(p),{method:'POST',headers:{'Content-Type':'application/json','Accept':'application/json'},body:JSON.stringify(body)});
  if(!r.ok) throw new Error(`${r.status}`);
  return r.json() as Promise<T>;
}
export async function uploadFile(file:File){
  const form=new FormData(); form.append('file',file);
  const r=await fetch(url('/api/v1/upload'),{method:'POST',body:form});
  if(!r.ok) throw new Error('UPLOAD');
  return r.json() as Promise<{ok:boolean,url:string,type:'image'|'video'}>;
}

// API wrappers
export const api = {
  points: (q:any)=> getJSON('/api/v1/map/points', q),
  pointCats: ()=> getJSON('/api/v1/points/categories'),
  addPoint: (body:any)=> postJSON('/api/v1/points', body),

  weather: (q:any)=> getJSON('/api/v1/weather', q),

  feed: (q:any)=> getJSON('/api/v1/feed', q),
  catchById: (id:number)=> getJSON(`/api/v1/catch/${id}`),
  addCatch: (body:any)=> postJSON('/api/v1/catches', body),
  catchMarkers: (q:any)=> getJSON('/api/v1/catches/markers', q),

  comment: (id:number, body:any)=> postJSON(`/api/v1/catch/${id}/comments`, body),
  like: (id:number, body:any)=> postJSON(`/api/v1/catch/${id}/like`, body),
  follow: (userId:number, body:any)=> postJSON(`/api/v1/follow/${userId}`, body),
};
TS

# -------- Мини UI (glass) --------
cat > "$FRONT/src/components/ui.tsx" <<'TSX'
import React from "react";
export const Card = ({children,className=""}:{children:any;className?:string}) =>
  <div className={"rounded-2xl bg-white/70 backdrop-blur border border-white/60 shadow-md "+className}>{children}</div>;
export const CardContent = ({children,className=""}:{children:any;className?:string}) =>
  <div className={"p-4 "+className}>{children}</div>;
export const Button = ({children,onClick,type="button",variant="default",className=""}:{children:any;onClick?:any;type?:"button"|"submit";variant?:"default"|"secondary"|"ghost";className?:string;})=>{
  const map:any={default:"bg-black text-white",secondary:"bg-white/70 border border-white/60",ghost:"bg-transparent"};
  return <button type={type} onClick={onClick} className={`rounded-full px-4 py-2 ${map[variant]} ${className}`}>{children}</button>;
};
export const Input = (p:React.InputHTMLAttributes<HTMLInputElement>) =>
  <input {...p} className={"w-full rounded-xl px-3 py-2 bg-white/70 backdrop-blur border border-white/60 outline-none "+(p.className||"")} />;
export const Textarea = (p:React.TextareaHTMLAttributes<HTMLTextAreaElement>) =>
  <textarea {...p} className={"w-full rounded-xl px-3 py-2 bg-white/70 backdrop-blur border border-white/60 outline-none "+(p.className||"")} />;
export const Select = ({value,onChange,children,className=""}:{value:any;onChange:any;children:any;className?:string}) =>
  <select value={value} onChange={onChange} className={"w-full rounded-xl px-3 py-2 bg-white/70 backdrop-blur border border-white/60 outline-none "+className}>{children}</select>;
TSX

# -------- Тост --------
cat > "$FRONT/src/lib/toast.ts" <<'TS'
export function toast(msg:string){
  const el=document.createElement('div'); el.textContent=msg;
  el.className='fixed left-1/2 -translate-x-1/2 bottom-24 px-4 py-2 rounded-full bg-black/70 text-white text-sm z-[1000]';
  document.body.appendChild(el); setTimeout(()=>el.remove(),2200);
}
TS

# -------- Карта и пикер --------
cat > "$FRONT/src/components/map/MapPicker.tsx" <<'TSX'
import React, {useEffect,useRef} from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
type Props={lat?:number;lng?:number;onPick:(lat:number,lng:number)=>void;height?:number|string};
export default function MapPicker({lat=55.7558,lng=37.6173,onPick,height=400}:Props){
  const ref=useRef<HTMLDivElement>(null); const markerRef=useRef<L.Marker|null>(null);
  useEffect(()=>{ if(!ref.current) return;
    const map=L.map(ref.current,{zoomControl:true,attributionControl:false}).setView([lat,lng],11);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(map);
    markerRef.current=L.marker([lat,lng],{draggable:true}).addTo(map);
    const ondrag=()=>{const p=markerRef.current!.getLatLng(); onPick(p.lat,p.lng);};
    markerRef.current.on('dragend',ondrag);
    map.on('click',(e:any)=>{const {lat,lng}=e.latlng; markerRef.current!.setLatLng([lat,lng]); onPick(lat,lng);});
    return ()=>{ map.remove(); };
  },[]);
  return <div ref={ref} style={{height}} className="rounded-2xl overflow-hidden border border-white/60" />;
}
TSX

# -------- Страницы: Добавить улов --------
cat > "$FRONT/src/screens/AddCatchPage.tsx" <<'TSX'
import React,{useEffect,useMemo,useState} from "react";
import {Card,CardContent,Button,Input,Textarea,Select} from "../components/ui";
import MapPicker from "../components/map/MapPicker";
import {api, uploadFile} from "../lib/api";
import {toast} from "../lib/toast";

export default function AddCatchPage(){
  const [form,setForm]=useState({lat:55.7558,lng:37.6173,species:"",length:"",weight:"",style:"",lure:"",tackle:"",notes:"",photo_url:"",caught_at:"",privacy:"all",water_type:"",water_temp:"",wind_speed:"",pressure:""});
  const set=(k:string,v:any)=>setForm(p=>({...p,[k]:v}));
  const ts=useMemo(()=> form.caught_at? Math.floor(new Date(form.caught_at).getTime()/1000) : null,[form.caught_at]);
  useEffect(()=>{ if(!form.lat||!form.lng) return; (async()=>{
      try{ const j:any=await api.weather({lat:form.lat,lng:form.lng,dt:ts||undefined});
        const c = j?.data?.current ?? null;
        if(c){ if(c.temp!=null) set('water_temp',c.temp); if(c.wind_speed!=null) set('wind_speed',c.wind_speed); if(c.pressure!=null) set('pressure',c.pressure); }
      }catch{}
  })(); },[form.lat,form.lng,ts]);
  const onUpload=async(e:React.ChangeEvent<HTMLInputElement>)=>{
    const f=e.target.files?.[0]; if(!f) return;
    try{ const u=await uploadFile(f); set('photo_url',u.url); toast('Файл загружен'); }catch{ toast('Ошибка загрузки'); }
    e.target.value="";
  };
  const submit=async(e:React.FormEvent)=>{ e.preventDefault();
    try{
      await api.addCatch({
        lat:Number(form.lat),lng:Number(form.lng),species:form.species||null,length:form.length?Number(form.length):null,
        weight:form.weight?Number(form.weight):null,style:form.style||null,lure:form.lure||null,tackle:form.tackle||null,
        notes:form.notes||null,photo_url:form.photo_url||null,caught_at:form.caught_at||null,privacy:form.privacy||"all",
        water_type:form.water_type||null,water_temp:form.water_temp?Number(form.water_temp):null,wind_speed:form.wind_speed?Number(form.wind_speed):null,pressure:form.pressure?Number(form.pressure):null
      });
      toast('Улов добавлен'); location.hash="#/feed";
    }catch{ toast('Ошибка сохранения'); }
  };
  return <div className="p-4 pb-28 max-w-3xl mx-auto">
    <Card><CardContent>
      <form onSubmit={submit} className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <Input placeholder="Вид рыбы" value={form.species} onChange={e=>set('species',e.target.value)} />
          <Input placeholder="Дата/время" type="datetime-local" value={form.caught_at} onChange={e=>set('caught_at',e.target.value)} />
          <Input placeholder="Вес (кг)" value={form.weight} onChange={e=>set('weight',e.target.value)} />
          <Input placeholder="Длина (см)" value={form.length} onChange={e=>set('length',e.target.value)} />
          <Input placeholder="Стиль" value={form.style} onChange={e=>set('style',e.target.value)} />
          <Input placeholder="Приманка" value={form.lure} onChange={e=>set('lure',e.target.value)} />
          <Input placeholder="Снасти" value={form.tackle} onChange={e=>set('tackle',e.target.value)} />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Input placeholder="Широта (lat)" value={form.lat} onChange={e=>set('lat',Number(e.target.value))} />
          <Input placeholder="Долгота (lng)" value={form.lng} onChange={e=>set('lng',Number(e.target.value))} />
        </div>
        <MapPicker lat={form.lat} lng={form.lng} onPick={(a,b)=>{set('lat',a);set('lng',b);}} height={420}/>
        <div className="flex items-center gap-3">
          <label className="rounded-full px-4 py-2 bg-white/70 border border-white/60 cursor-pointer">
            Загрузить фото/видео <input type="file" className="hidden" accept="image/*,video/*" onChange={onUpload}/>
          </label>
          {form.photo_url && <span className="text-xs break-all">{form.photo_url}</span>}
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <Select value={form.privacy} onChange={e=>set('privacy',e.target.value)}>
            <option value="all">Публично</option><option value="friends">Друзья</option><option value="private">Приватно</option>
          </Select>
          <Input placeholder="Тип воды" value={form.water_type} onChange={e=>set('water_type',e.target.value)} />
          <Input placeholder="Температура (°C)" value={form.water_temp} onChange={e=>set('water_temp',e.target.value)} />
          <Input placeholder="Ветер (м/с)" value={form.wind_speed} onChange={e=>set('wind_speed',e.target.value)} />
          <Input placeholder="Давление (гПа)" value={form.pressure} onChange={e=>set('pressure',e.target.value)} />
        </div>
        <Textarea placeholder="Заметки" value={form.notes} onChange={e=>set('notes',e.target.value)} />
        <div className="flex justify-end gap-2">
          <Button variant="secondary" onClick={()=>history.back()}>Отмена</Button>
          <Button type="submit">Сохранить улов</Button>
        </div>
      </form>
    </CardContent></Card>
  </div>;
}
TSX

# -------- Страница: Добавить место --------
cat > "$FRONT/src/screens/AddPlacePage.tsx" <<'TSX'
import React,{useEffect,useState} from "react";
import {Card,CardContent,Button,Input,Textarea,Select} from "../components/ui";
import MapPicker from "../components/map/MapPicker";
import {api, uploadFile} from "../lib/api";
import {toast} from "../lib/toast";

export default function AddPlacePage(){
  const [cats,setCats]=useState<string[]>(["spot","shop","slip","camp"]);
  const [form,setForm]=useState({title:"",description:"",category:"spot",lat:55.7558,lng:37.6173,is_public:true,is_highlighted:false,preview_url:""});
  const set=(k:string,v:any)=>setForm(p=>({...p,[k]:v}));
  useEffect(()=>{ api.pointCats().then((j:any)=>Array.isArray(j.items)&&setCats(j.items)).catch(()=>{}); },[]);
  const onUpload=async(e:React.ChangeEvent<HTMLInputElement>)=>{
    const f=e.target.files?.[0]; if(!f) return;
    try{ const u=await uploadFile(f); set('preview_url',u.url); toast('Файл загружен'); }catch{ toast('Ошибка загрузки'); }
    e.target.value="";
  };
  const submit=async(e:React.FormEvent)=>{ e.preventDefault();
    try{
      await api.addPoint({title:form.title,description:form.description||null,category:form.category,lat:Number(form.lat),lng:Number(form.lng),
        is_public:!!form.is_public,is_highlighted:!!form.is_highlighted,status:'approved'});
      toast('Место добавлено'); location.hash="#/";
    }catch{ toast('Ошибка сохранения'); }
  };
  return <div className="p-4 pb-28 max-w-3xl mx-auto">
    <Card><CardContent>
      <form onSubmit={submit} className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          <Input placeholder="Название" value={form.title} onChange={e=>set('title',e.target.value)} required />
          <Select value={form.category} onChange={e=>set('category',e.target.value)}>{cats.map(c=><option key={c} value={c}>{c}</option>)}</Select>
        </div>
        <Textarea placeholder="Описание" value={form.description} onChange={e=>set('description',e.target.value)} />
        <div className="grid grid-cols-2 gap-3">
          <Input placeholder="Широта (lat)" value={form.lat} onChange={e=>set('lat',Number(e.target.value))} />
          <Input placeholder="Долгота (lng)" value={form.lng} onChange={e=>set('lng',Number(e.target.value))} />
        </div>
        <MapPicker lat={form.lat} lng={form.lng} onPick={(a,b)=>{set('lat',a);set('lng',b);}} height={420}/>
        <div className="flex items-center gap-3">
          <label className="rounded-full px-4 py-2 bg-white/70 border border-white/60 cursor-pointer">
            Загрузить обложку <input type="file" className="hidden" accept="image/*" onChange={onUpload}/>
          </label>
          {form.preview_url && <span className="text-xs break-all">{form.preview_url}</span>}
        </div>
        <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={form.is_public} onChange={e=>set('is_public',e.target.checked)}/>Публично</label>
        <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={form.is_highlighted} onChange={e=>set('is_highlighted',e.target.checked)}/>Выделить</label>
        <div className="flex justify-end gap-2">
          <Button variant="secondary" onClick={()=>history.back()}>Отмена</Button>
          <Button type="submit">Сохранить место</Button>
        </div>
      </form>
    </CardContent></Card>
  </div>;
}
TSX

# -------- Лента (новые сверху, беск. скролл, клики) --------
cat > "$FRONT/src/screens/FeedScreen.tsx" <<'TSX'
import React,{useEffect,useRef,useState} from "react";
import {api} from "../lib/api";
import {toast} from "../lib/toast";

type FeedItem = {
  id:number,user_id:number,user_name:string,user_avatar?:string|null,
  lat:number,lng:number,species?:string|null,length?:number|null,weight?:number|null,
  notes?:string|null,photo_url?:string|null, created_at:string,
  likes_count:number, comments_count:number
};
export default function FeedScreen({placeId}:{placeId?:number}){
  const [items,setItems]=useState<FeedItem[]>([]);
  const [loading,setLoading]=useState(false);
  const [offset,setOffset]=useState(0);
  const doneRef=useRef(false);

  const load=async()=>{
    if(loading||doneRef.current) return; setLoading(true);
    try{
      const q:any={limit:20,offset};
      if(placeId) q.place_id=placeId;
      const j:any=await api.feed(q);
      const next=j.next_offset ?? (offset+(j.items?.length||0));
      setItems(prev=>[...prev,...(j.items||[])]);
      setOffset(next);
      if(!j.items || j.items.length===0) doneRef.current=true;
    }catch{ toast('Ошибка загрузки ленты'); }
    finally{ setLoading(false); }
  };

  useEffect(()=>{ // init
    setItems([]); setOffset(0); doneRef.current=false; load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  },[placeId]);

  useEffect(()=>{ // inf scroll
    const onScroll=()=>{
      if((window.innerHeight+window.scrollY)>=document.body.offsetHeight-400) load();
    };
    window.addEventListener('scroll',onScroll); return ()=>window.removeEventListener('scroll',onScroll);
  },[load]);

  return <div className="p-3 pb-28 max-w-2xl mx-auto space-y-3">
    {items.map(it=><div key={it.id} className="rounded-2xl bg-white/70 backdrop-blur border border-white/60 shadow-md overflow-hidden">
      <div className="flex items-center gap-3 px-4 py-3">
        <img src={it.user_avatar||'/avatar.svg'} className="w-9 h-9 rounded-full object-cover" onError={(e:any)=>e.currentTarget.src='/avatar.svg'}/>
        <div className="flex-1">
          <div className="font-medium cursor-pointer" onClick={()=>location.hash=`#/u/${it.user_id}`}>{it.user_name||'Рыбак'}</div>
          <div className="text-xs text-gray-500">{new Date(it.created_at).toLocaleString()}</div>
        </div>
        <button className="text-sm text-gray-600" onClick={()=>shareCatch(it.id)}>Поделиться</button>
      </div>
      {it.photo_url && <img src={it.photo_url} className="w-full max-h-[60vh] object-cover" />}
      <div className="px-4 py-3 text-sm space-y-2">
        <div className="flex flex-wrap gap-3">
          {it.species && <span className="px-3 py-1 rounded-full border cursor-pointer" onClick={()=>location.hash=`#/?species=${encodeURIComponent(it.species!)}`}>🐟 {it.species}</span>}
          <span className="px-3 py-1 rounded-full border cursor-pointer" onClick={()=>openNearby(it.lat,it.lng)}>📍 место</span>
        </div>
        {it.notes && <div>{it.notes}</div>}
        <div className="flex items-center justify-between pt-2 text-sm text-gray-700">
          <div className="flex items-center gap-4">
            <button onClick={()=>like(it.id)} title="Нравится">❤️ {it.likes_count}</button>
            <button onClick={()=>location.hash=`#/catch/${it.id}`} title="Комментарии">💬 {it.comments_count}</button>
          </div>
          <div className="flex items-center gap-4">
            <button onClick={()=>follow(it.user_id)}>➕ Подписаться</button>
            <button onClick={()=>report(it.id)} className="text-red-600">Пожаловаться</button>
          </div>
        </div>
      </div>
    </div>)}
    {loading && <div className="text-center text-gray-500 py-6">Загрузка…</div>}
    {!loading && items.length===0 && <div className="text-center text-gray-500 py-12">Пока пусто</div>}
  </div>;
}

function shareCatch(id:number){
  const link = `${location.origin}/#/catch/${id}`;
  if((navigator as any).share) (navigator as any).share({title:'Улов',url:link});
  else navigator.clipboard?.writeText(link);
}

async function like(id:number){
  try{ await fetch(`${(import.meta as any).env?.VITE_API_BASE||'https://api.fishtrackpro.ru'}/api/v1/catch/${id}/like`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({user_id:1})}); }catch{}
  location.hash=`#/catch/${id}`; // откроем деталь (для честного пересчёта)
}

async function report(id:number){
  alert('Жалоба отправлена (демо)');
}

async function follow(uid:number){
  try{ await fetch(`${(import.meta as any).env?.VITE_API_BASE||'https://api.fishtrackpro.ru'}/api/v1/follow/${uid}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({user_id:1})}); }catch{}
  alert('Готово');
}

function openNearby(lat:number,lng:number){
  // эмулируем переход к ленте по ближайшему месту: передадим координаты в хэше
  location.hash=`#/feed?near=${lat.toFixed(5)},${lng.toFixed(5)}`;
}
TSX

# -------- Детальная страница улова (комменты) --------
cat > "$FRONT/src/screens/CatchDetailPage.tsx" <<'TSX'
import React,{useEffect,useState} from "react";
import {api} from "../lib/api";
import {Input, Button, Card, CardContent} from "../components/ui";
import {toast} from "../lib/toast";

export default function CatchDetailPage({id}:{id:number}){
  const [item,setItem]=useState<any>(null);
  const [comments,setComments]=useState<any[]>([]);
  const [body,setBody]=useState("");

  useEffect(()=>{ (async()=>{
    try{
      const j:any=await api.catchById(id);
      setItem(j.item); setComments(j.comments||[]);
    }catch{ toast('Не найдено'); history.back(); }
  })(); },[id]);

  const send=async()=>{
    if(!body.trim()) return;
    try{ await api.comment(id,{body, user_id:1}); setBody(""); const j:any=await api.catchById(id); setComments(j.comments||[]); }
    catch{ toast('Ошибка'); }
  };

  if(!item) return <div className="p-6 text-center text-gray-500">Загрузка…</div>;
  return <div className="p-3 pb-28 max-w-2xl mx-auto space-y-3">
    <Card><CardContent>
      <div className="flex items-center gap-3">
        <img src={item.user_avatar||'/avatar.svg'} className="w-9 h-9 rounded-full object-cover" onClick={()=>location.hash=`#/u/${item.user_id}`}/>
        <div className="flex-1">
          <div className="font-medium cursor-pointer" onClick={()=>location.hash=`#/u/${item.user_id}`}>{item.user_name||'Рыбак'}</div>
          <div className="text-xs text-gray-500">{new Date(item.created_at).toLocaleString()}</div>
        </div>
        <button className="text-sm text-gray-600" onClick={()=>navigator.clipboard?.writeText(location.href)}>Поделиться</button>
      </div>
      {item.photo_url && <img src={item.photo_url} className="w-full max-h-[70vh] object-cover rounded-xl mt-3" />}
      <div className="mt-3 flex flex-wrap gap-3 text-sm">
        {item.species && <span className="px-3 py-1 border rounded-full cursor-pointer" onClick={()=>location.hash=`#/?species=${encodeURIComponent(item.species)}`}>🐟 {item.species}</span>}
        <span className="px-3 py-1 border rounded-full cursor-pointer" onClick={()=>location.hash=`#/feed?near=${item.lat},${item.lng}`}>📍 место</span>
      </div>
      {item.notes && <div className="mt-3">{item.notes}</div>}
      <div className="mt-3 text-sm text-gray-700 flex items-center gap-4">
        <span>❤️ {item.likes_count}</span>
        <span>💬 {item.comments_count}</span>
      </div>
    </CardContent></Card>

    <Card><CardContent>
      <div className="text-sm font-medium mb-2">Комментарии</div>
      <div className="space-y-3">
        {comments.map(c=><div key={c.id} className="flex items-start gap-3">
          <img src={c.user_avatar||'/avatar.svg'} className="w-7 h-7 rounded-full object-cover"/>
          <div>
            <div className="text-sm font-medium">{c.user_name}</div>
            <div className="text-sm">{c.body}</div>
          </div>
        </div>)}
        {comments.length===0 && <div className="text-gray-500 text-sm">Пока нет комментариев</div>}
      </div>
      <div className="flex gap-2 mt-4">
        <Input placeholder="Написать комментарий…" value={body} onChange={e=>setBody(e.target.value)} />
        <Button onClick={send}>Отпр.</Button>
      </div>
    </CardContent></Card>
  </div>;
}
TSX

# -------- MapScreen: учитываем species в query, маркеры уловов при выборе вида --------
cat > "$FRONT/src/screens/MapScreen.tsx" <<'TSX'
import React,{useEffect,useMemo,useRef} from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import {api} from "../lib/api";

export default function MapScreen(){
  const ref=useRef<HTMLDivElement>(null);
  const species=useMemo(()=> new URLSearchParams(location.hash.split('?')[1]||'').get('species') || '', []);
  useEffect(()=>{ if(!ref.current) return;
    const center:[number,number]=[55.7558,37.6173];
    const map=L.map(ref.current,{zoomControl:true,attributionControl:false}).setView(center,11);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{maxZoom:19}).addTo(map);
    const group=L.layerGroup().addTo(map);

    async function load(){
      group.clearLayers();
      if(species){
        const j:any=await api.catchMarkers({species});
        (j.items||[]).forEach((m:any)=>{
          L.marker([m.lat,m.lng]).addTo(group).bindPopup(`<b>${m.species||''}</b> <br/><a href="#/catch/${m.id}">Открыть улов</a>`);
        });
      }else{
        const bounds=map.getBounds(); const bbox=[bounds.getWest(),bounds.getSouth(),bounds.getEast(),bounds.getNorth()].join(',');
        const j:any=await api.points({limit:500,bbox});
        (j.items||[]).forEach((p:any)=>{
          L.marker([p.lat,p.lng]).addTo(group).bindPopup(`<b>${p.title||''}</b>`);
        });
      }
    }
    load(); map.on('moveend',()=>{ if(!species) load(); });

    return ()=>{ map.remove(); };
  },[species]);

  return <div className="w-full h-[calc(100vh-84px)]">{/* 84px под нижнюю навигацию */}
    <div ref={ref} className="w-full h-full" />
  </div>;
}
TSX

# -------- Простой хеш-роутер и App --------
cat > "$FRONT/src/App.tsx" <<'TSX'
import React,{useEffect,useState} from "react";
import MapScreen from "./screens/MapScreen";
import FeedScreen from "./screens/FeedScreen";
import AddCatchPage from "./screens/AddCatchPage";
import AddPlacePage from "./screens/AddPlacePage";
import CatchDetailPage from "./screens/CatchDetailPage";
import BottomNav from "./components/BottomNav";

type Route = {path:string, params:Record<string,string>};

function parseHash():Route{
  const h=location.hash.replace(/^#\/?/,''); // e.g. "catch/12?x=1"
  const [pathPart, qs] = h.split('?');
  const params:Object = Object.fromEntries(new URLSearchParams(qs||'').entries());
  return {path: pathPart||'', params: params as any};
}

export default function App(){
  const [route,setRoute]=useState<Route>(parseHash());
  useEffect(()=>{ const onHash=()=>setRoute(parseHash()); window.addEventListener('hashchange',onHash); return ()=>window.removeEventListener('hashchange',onHash);},[]);

  const activeTab = route.path.startsWith('feed') ? 'feed' : route.path==='' ? 'map' : route.path.startsWith('profile') ? 'profile' : 'map';

  let page:any=null;
  if(route.path==='') page=<MapScreen/>;
  else if(route.path.startsWith('feed')) page=<FeedScreen/>;
  else if(route.path.startsWith('add/catch')) page=<AddCatchPage/>;
  else if(route.path.startsWith('add/place')) page=<AddPlacePage/>;
  else if(route.path.startsWith('catch/')){
    const id=parseInt(route.path.split('/')[1]||'0',10); page=<CatchDetailPage id={id}/>;
  } else page=<MapScreen/>;

  return <div className="w-full h-screen bg-gray-100">
    {page}
    <BottomNav onFab={()=>{ location.hash="#/add/catch"; }} active={activeTab as any} onChange={(t:any)=>{
      if(t==='map') location.hash='#/';
      else if(t==='feed') location.hash='#/feed';
      else if(t==='profile') location.hash='#/profile';
      else location.hash='#/';
    }}/>
  </div>;
}
TSX

echo "==> Готово. Не забудьте очистить кэш роутов и пересобрать фронт."