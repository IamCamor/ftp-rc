#!/usr/bin/env bash
set -euo pipefail

FRONT="frontend/src"
PAGES="$FRONT/pages"
STYLES="$FRONT/styles"
UTILS="$FRONT/utils"

[ -d "frontend" ] || { echo "❌ Не найдена папка frontend (запусти из корня проекта)"; exit 1; }
mkdir -p "$PAGES" "$UTILS"

########################################
# api.ts — фолбэки маршрутов + формы
########################################
cat > "$FRONT/api.ts" <<'TS'
import config from './config';

type FetchOpts = {
  method?: 'GET'|'POST'|'PUT'|'DELETE',
  body?: any,
  headers?: Record<string,string>,
  credentials?: RequestCredentials
};

function joinUrl(base:string, path:string) {
  if (path.startsWith('http')) return path;
  const b = base.replace(/\/+$/,''); const p = path.replace(/^\/+/,'');
  return `${b}/${p}`;
}

async function httpRaw(url:string, opts:FetchOpts): Promise<Response> {
  return fetch(url, {
    method: opts.method ?? 'GET',
    headers: opts.headers,
    credentials: opts.credentials ?? 'include',
    body: opts.body
  });
}

/**
 * Пробуем несколько префиксов:
 *   /api/v1/xxx  → /api/xxx → /xxx
 */
async function httpTry<T=any>(path:string, opts:FetchOpts = {}): Promise<T> {
  const variants = [
    path.startsWith('/api/v1/') ? path : `/api/v1${path.startsWith('/')?path:`/${path}`}`,
    path.startsWith('/api/') ? path : `/api${path.startsWith('/')?path:`/${path}`}`,
    path.startsWith('/') ? path : `/${path}`,
  ];

  let lastErr:any = null;
  for (const v of variants) {
    try {
      const url = joinUrl(config.apiBase, v);
      const res = await httpRaw(url, opts);
      const text = await res.text();
      let json:any; try { json = text ? JSON.parse(text) : {}; } catch { json = text; }
      if (!res.ok) { lastErr = {status:res.status, payload:json}; continue; }
      return json as T;
    } catch (e:any) {
      lastErr = e;
      continue;
    }
  }
  const err:any = new Error((lastErr && (lastErr.payload?.message || lastErr.payload?.error)) || 'Network/Route error');
  err.cause = lastErr; throw err;
}

function normalizeArray(payload:any): any[] {
  if (Array.isArray(payload)) return payload;
  if (!payload) return [];
  if (Array.isArray(payload.items)) return payload.items;
  if (Array.isArray(payload.data)) return payload.data;
  if (Array.isArray(payload.results)) return payload.results;
  if (Array.isArray(payload.rows)) return payload.rows;
  return [];
}

export type PointsQuery = { limit?: number; bbox?: string | [number,number,number,number]; filter?: string };
export async function points(q: PointsQuery = {}): Promise<any[]> {
  const p = new URLSearchParams();
  if (q.limit) p.set('limit', String(q.limit));
  if (q.filter) p.set('filter', q.filter);
  if (q.bbox) p.set('bbox', Array.isArray(q.bbox) ? q.bbox.join(',') : q.bbox);
  const res = await httpTry<any>(`/map/points?${p.toString()}`, { method:'GET' });
  return normalizeArray(res);
}

export async function feed(limit=10, offset=0): Promise<any[]> {
  const res = await httpTry<any>(`/feed?limit=${limit}&offset=${offset}`, { method:'GET' });
  return normalizeArray(res);
}

export async function profileMe(): Promise<any> {
  return httpTry<any>('/profile/me', { method:'GET' });
}

export async function notifications(): Promise<any[]> {
  const res = await httpTry<any>('/notifications', { method:'GET' });
  return normalizeArray(res);
}

/** Форматируем ISO/строку в MySQL DATETIME (локально) */
export function toMysqlDatetime(input: string|Date): string {
  const d = typeof input === 'string' ? new Date(input) : input;
  const pad = (n:number)=> (n<10?'0':'')+n;
  return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

/** submit multipart */
async function postMultipart<T=any>(path:string, data:Record<string,any>): Promise<T> {
  const fd = new FormData();
  Object.entries(data).forEach(([k,v])=>{
    if (v === undefined || v === null) return;
    if (Array.isArray(v)) v.forEach((vv)=> fd.append(k, vv as any));
    else fd.append(k, v as any);
  });
  return httpTry<T>(path, { method:'POST', body: fd, credentials:'include' });
}

/** submit json */
async function postJson<T=any>(path:string, data:any): Promise<T> {
  return httpTry<T>(path, { method:'POST', body: JSON.stringify(data), headers:{'Content-Type':'application/json'} });
}

/** ====== Catch ====== */
export type CatchPayload = {
  lat:number; lng:number;
  species:string;
  length?:number; weight?:number;
  style?:string; lure?:string; tackle?:string;
  notes?:string;
  photo?: File|null;
  caught_at: string; // YYYY-MM-DD HH:mm:ss
  privacy?: 'all'|'friends'|'private';
};
export async function createCatch(payload: CatchPayload): Promise<any> {
  const body:any = { ...payload };
  if (payload.photo) body.photo = payload.photo;
  return postMultipart('/catch', body);
}

/** ====== Place ====== */
export type PlacePayload = {
  title:string;
  description?:string;
  lat:number; lng:number;
  water_type?: 'river'|'lake'|'sea'|'pond'|'other';
  access?: 'free'|'paid'|'restricted';
  season?: string;
  tags?: string;
  photos?: File[];
  privacy?: 'all'|'friends'|'private';
};
export async function createPlace(payload: PlacePayload): Promise<any> {
  const body:any = { ...payload };
  if (payload.photos && payload.photos.length) {
    body.photos = payload.photos; // backend должен принять массив
  }
  return postMultipart('/places', body);
}
export async function getPlaceById(id: string|number): Promise<any> {
  return httpTry<any>(`/places/${id}`, { method:'GET' });
}

const LS_KEY = 'weather_favs_v1';
export type WeatherFav = { lat:number; lng:number; name:string };
export function getWeatherFavs(): WeatherFav[] {
  try { return JSON.parse(localStorage.getItem(LS_KEY) || '[]'); } catch { return []; }
}
export async function saveWeatherFav(f: WeatherFav): Promise<void> {
  const list = getWeatherFavs(); list.push(f);
  localStorage.setItem(LS_KEY, JSON.stringify(list));
}

TS

########################################
# AddCatchPage.tsx — полноценная форма
########################################
cat > "$PAGES/AddCatchPage.tsx" <<'TS'
import React, { useState } from 'react';
import { createCatch, toMysqlDatetime } from '../api';
import { useNavigate } from 'react-router-dom';

const AddCatchPage:React.FC = () => {
  const nav = useNavigate();
  const qs = new URLSearchParams(location.search);
  const [lat, setLat] = useState<number>(Number(qs.get('lat')) || 55.75);
  const [lng, setLng] = useState<number>(Number(qs.get('lng')) || 37.61);
  const [species, setSpecies] = useState('');
  const [length, setLength] = useState<number|''>('');
  const [weight, setWeight] = useState<number|''>('');
  const [style, setStyle] = useState('');
  const [lure, setLure] = useState('');
  const [tackle, setTackle] = useState('');
  const [notes, setNotes] = useState('');
  const [photo, setPhoto] = useState<File|null>(null);
  const [caughtAt, setCaughtAt] = useState<string>(new Date().toISOString().slice(0,16)); // yyyy-MM-ddTHH:mm
  const [privacy, setPrivacy] = useState<'all'|'friends'|'private'>('all');
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string>('');

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!species.trim()) { setMsg('Укажите вид рыбы'); return; }
    setBusy(true); setMsg('');
    try {
      const payload = {
        lat, lng, species,
        length: length === '' ? undefined : Number(length),
        weight: weight === '' ? undefined : Number(weight),
        style, lure, tackle, notes,
        photo,
        caught_at: toMysqlDatetime(new Date(caughtAt)),
        privacy
      };
      const res = await createCatch(payload);
      setMsg('✅ Улов добавлен');
      const id = res?.id;
      setTimeout(()=> nav(id ? `/catch/${id}` : '/feed'), 600);
    } catch (e:any) {
      setMsg(`Ошибка: ${e?.message || 'не удалось отправить'}`);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="container">
      <form className="glass card" style={{marginTop:16}} onSubmit={submit}>
        <h2>Добавить улов</h2>
        {msg && <div className="subtle" style={{marginBottom:8}}>{msg}</div>}
        <div style={{display:'grid', gap:10}}>
          <label>Вид рыбы* <input value={species} onChange={e=>setSpecies(e.target.value)} required/></label>
          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Длина (см) <input type="number" step="0.1" value={length} onChange={e=>setLength(e.target.value===''?'':Number(e.target.value))} /></label>
            <label>Вес (кг) <input type="number" step="0.01" value={weight} onChange={e=>setWeight(e.target.value===''?'':Number(e.target.value))} /></label>
          </div>
          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Метод <input value={style} onChange={e=>setStyle(e.target.value)} /></label>
            <label>Приманка <input value={lure} onChange={e=>setLure(e.target.value)} /></label>
          </div>
          <label>Снасть <input value={tackle} onChange={e=>setTackle(e.target.value)} /></label>
          <label>Заметки <textarea value={notes} onChange={e=>setNotes(e.target.value)} rows={3} /></label>

          <label>Фото
            <input type="file" accept="image/*" onChange={e=>setPhoto(e.target.files?.[0] || null)} />
          </label>

          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Широта <input type="number" step="0.00001" value={lat} onChange={e=>setLat(Number(e.target.value))} /></label>
            <label>Долгота <input type="number" step="0.00001" value={lng} onChange={e=>setLng(Number(e.target.value))} /></label>
          </div>

          <label>Дата/время
            <input type="datetime-local" value={caughtAt} onChange={e=>setCaughtAt(e.target.value)} />
          </label>

          <label>Приватность
            <select value={privacy} onChange={e=>setPrivacy(e.target.value as any)}>
              <option value="all">Все</option>
              <option value="friends">Друзья</option>
              <option value="private">Только я</option>
            </select>
          </label>

          <div style={{display:'flex', gap:8}}>
            <button className="btn" disabled={busy} type="submit">
              <span className="material-symbols-rounded">save</span> Сохранить
            </button>
            <button className="btn" type="button" onClick={()=>history.back()}><span className="material-symbols-rounded">arrow_back</span>Назад</button>
          </div>
        </div>
      </form>
    </div>
  );
};
export default AddCatchPage;
TS

########################################
# AddPlacePage.tsx — полноценная форма
########################################
cat > "$PAGES/AddPlacePage.tsx" <<'TS'
import React, { useState } from 'react';
import { createPlace } from '../api';
import { useNavigate } from 'react-router-dom';

const AddPlacePage:React.FC = () => {
  const nav = useNavigate();
  const qs = new URLSearchParams(location.search);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [lat, setLat] = useState<number>(Number(qs.get('lat')) || 55.75);
  const [lng, setLng] = useState<number>(Number(qs.get('lng')) || 37.61);
  const [waterType, setWaterType] = useState<'river'|'lake'|'sea'|'pond'|'other'>('river');
  const [access, setAccess] = useState<'free'|'paid'|'restricted'>('free');
  const [season, setSeason] = useState('');
  const [tags, setTags] = useState('');
  const [photos, setPhotos] = useState<File[]>([]);
  const [privacy, setPrivacy] = useState<'all'|'friends'|'private'>('all');
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState('');

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) { setMsg('Название обязательно'); return; }
    setBusy(true); setMsg('');
    try {
      const res = await createPlace({
        title, description, lat, lng,
        water_type: waterType, access, season, tags,
        photos, privacy
      });
      setMsg('✅ Место добавлено');
      const id = res?.id;
      setTimeout(()=> nav(id ? `/place/${id}` : '/map'), 600);
    } catch (e:any) {
      setMsg(`Ошибка: ${e?.message || 'не удалось отправить'}`);
    } finally { setBusy(false); }
  }

  return (
    <div className="container">
      <form className="glass card" style={{marginTop:16}} onSubmit={submit}>
        <h2>Добавить место</h2>
        {msg && <div className="subtle" style={{marginBottom:8}}>{msg}</div>}
        <div style={{display:'grid', gap:10}}>
          <label>Название* <input value={title} onChange={e=>setTitle(e.target.value)} required/></label>
          <label>Описание <textarea rows={3} value={description} onChange={e=>setDescription(e.target.value)} /></label>

          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Широта <input type="number" step="0.00001" value={lat} onChange={e=>setLat(Number(e.target.value))} /></label>
            <label>Долгота <input type="number" step="0.00001" value={lng} onChange={e=>setLng(Number(e.target.value))} /></label>
          </div>

          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Водоём
              <select value={waterType} onChange={e=>setWaterType(e.target.value as any)}>
                <option value="river">Река</option>
                <option value="lake">Озеро</option>
                <option value="sea">Море</option>
                <option value="pond">Пруд</option>
                <option value="other">Другое</option>
              </select>
            </label>
            <label>Доступ
              <select value={access} onChange={e=>setAccess(e.target.value as any)}>
                <option value="free">Свободный</option>
                <option value="paid">Платный</option>
                <option value="restricted">Ограниченный</option>
              </select>
            </label>
          </div>

          <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:10}}>
            <label>Сезон/период <input value={season} onChange={e=>setSeason(e.target.value)} placeholder="весна, лето…"/></label>
            <label>Теги <input value={tags} onChange={e=>setTags(e.target.value)} placeholder="окунь, лодка…"/></label>
          </div>

          <label>Фото
            <input multiple type="file" accept="image/*" onChange={e=>setPhotos(Array.from(e.target.files || []))} />
          </label>

          <label>Приватность
            <select value={privacy} onChange={e=>setPrivacy(e.target.value as any)}>
              <option value="all">Все</option>
              <option value="friends">Друзья</option>
              <option value="private">Только я</option>
            </select>
          </label>

          <div style={{display:'flex', gap:8}}>
            <button className="btn" disabled={busy} type="submit">
              <span className="material-symbols-rounded">save</span> Сохранить
            </button>
            <button className="btn" type="button" onClick={()=>history.back()}><span className="material-symbols-rounded">arrow_back</span>Назад</button>
          </div>
        </div>
      </form>
    </div>
  );
};
export default AddPlacePage;
TS

########################################
# PlaceDetailPage.tsx — детальная страница
########################################
cat > "$PAGES/PlaceDetailPage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { getPlaceById } from '../api';

const PlaceDetailPage:React.FC = () => {
  const { id } = useParams();
  const [data, setData] = useState<any>(null);
  const [err, setErr] = useState('');

  useEffect(() => {
    (async() => {
      try { setData(await getPlaceById(id!)); }
      catch(e:any){ setErr(e?.message || 'Ошибка загрузки'); }
    })();
  }, [id]);

  if (err) return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Место</h2>
        <div className="subtle">{err}</div>
      </div>
    </div>
  );

  if (!data) return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Место</h2>
        <div className="subtle">Загрузка…</div>
      </div>
    </div>
  );

  const photos:string[] = data.photos || data.media || (data.photo_url ? [data.photo_url] : []) || [];

  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>{data.title || 'Место'}</h2>
        {photos.length > 0 && (
          <div style={{display:'grid', gridTemplateColumns:'repeat(auto-fill,minmax(160px,1fr))', gap:8, margin:'8px 0'}}>
            {photos.map((src:string, i:number)=> (
              <img key={i} src={src} alt="" style={{width:'100%', height:120, objectFit:'cover', borderRadius:12}}/>
            ))}
          </div>
        )}
        <div className="subtle" style={{margin:'8px 0'}}>
          {data.description || 'Нет описания'}
        </div>
        <div style={{display:'flex', gap:12, flexWrap:'wrap', marginTop:6}}>
          <span className="subtle"><span className="material-symbols-rounded">location_on</span> {data.lat?.toFixed?.(5)}, {data.lng?.toFixed?.(5)}</span>
          {data.water_type && <span className="subtle"><span className="material-symbols-rounded">waves</span> {data.water_type}</span>}
          {data.access && <span className="subtle"><span className="material-symbols-rounded">lock_open</span> {data.access}</span>}
        </div>
        <div style={{display:'flex', gap:8, marginTop:12}}>
          <Link to="/map" className="btn"><span className="material-symbols-rounded">map</span> На карту</Link>
          <Link to="/feed" className="btn"><span className="material-symbols-rounded">home</span> В ленту</Link>
        </div>
      </div>
    </div>
  );
};
export default PlaceDetailPage;
TS

echo "✅ Обновлены:"
echo " - $FRONT/api.ts"
echo " - $PAGES/AddCatchPage.tsx"
echo " - $PAGES/AddPlacePage.tsx"
echo " - $PAGES/PlaceDetailPage.tsx"
echo
echo "Готово. Запусти: cd frontend && npm run dev   (или npm run build)"