#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
SRC="$ROOT/src"
[ -d "$ROOT/frontend/src" ] && SRC="$ROOT/frontend/src"

mkdir -p "$SRC/components" "$SRC/pages" "$SRC/styles" "$SRC/utils" "$SRC/assets"

############################################
# 1) Расширяем config.ts: новые иконки + слоты баннеров
############################################
cat > "$SRC/config.ts" <<'TS'
export type AppConfig = {
  apiBase: string;
  siteBase: string;
  images: {
    logoUrl: string;
    defaultAvatar: string;
    backgroundPattern: string;
  };
  icons: {
    like: string;
    comment: string;
    share: string;
    map: string;
    add: string;
    alerts: string;
    profile: string;
    weather: string;
    home: string;
    star: string;
    gift: string;
    friends: string;
    settings: string;
    leaderboard: string;
    ad: string;
  };
  banners: {
    // через сколько элементов ленты вставлять баннер-слот
    feedEvery: number;
  }
};

const config: AppConfig = {
  apiBase: 'https://api.fishtrackpro.ru/api/v1',
  siteBase: 'https://www.fishtrackpro.ru',
  images: {
    logoUrl: '/assets/logo.svg',
    defaultAvatar: '/assets/default-avatar.png',
    backgroundPattern: '/assets/bg-pattern.png',
  },
  icons: {
    like: 'favorite',
    comment: 'chat_bubble',
    share: 'share',
    map: 'map',
    add: 'add_location_alt',
    alerts: 'notifications',
    profile: 'account_circle',
    weather: 'partly_cloudy_day',
    home: 'home',
    star: 'star',
    gift: 'redeem',
    friends: 'group',
    settings: 'settings',
    leaderboard: 'military_tech',
    ad: 'brand_awareness',
  },
  banners: {
    feedEvery: 5
  }
};

export default config;
TS

############################################
# 2) Дополняем api.ts: рейтинг, друзья, баннеры, бонусы, настройки
############################################
cat > "$SRC/api.ts" <<'TS'
import config from './config';

type HttpOptions = {
  method?: 'GET'|'POST'|'PUT'|'PATCH'|'DELETE';
  body?: any;
  auth?: boolean;
  headers?: Record<string,string>;
};

function getToken(): string | null {
  try { return localStorage.getItem('token'); } catch { return null; }
}

async function http<T=any>(url: string, opts: HttpOptions = {}): Promise<T> {
  const { method='GET', body, auth=true, headers={} } = opts;
  const token = getToken();

  const res = await fetch(url, {
    method,
    mode: 'cors',
    credentials: 'omit',
    headers: {
      'Accept': 'application/json',
      ...(body ? {'Content-Type': 'application/json'} : {}),
      ...(auth && token ? { 'Authorization': `Bearer ${token}` } : {}),
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (res.status === 204) return undefined as unknown as T;

  let data: any = null;
  const text = await res.text().catch(()=> '');
  try { data = text ? JSON.parse(text) : null; } catch { data = text; }

  if (!res.ok) {
    const msg = (data && (data.message || data.error)) || `${res.status} ${res.statusText}`;
    throw new Error(msg);
  }
  return data as T;
}

function unwrap<T=any>(x: any, fallback: T): T {
  if (x == null) return fallback;
  if (Array.isArray(x)) return x as T;
  if (typeof x === 'object' && Array.isArray((x as any).data)) return (x as any).data as T;
  return x as T;
}

const base = config.apiBase;

/** FEED */
export async function feed(params: {limit?: number; offset?: number} = {}) {
  const q = new URLSearchParams();
  if (params.limit) q.set('limit', String(params.limit));
  if (params.offset) q.set('offset', String(params.offset));
  const r = await http<any>(`${base}/feed${q.toString()?`?${q.toString()}`:''}`);
  return unwrap<any[]>(r, []);
}

/** MAP */
export async function points(bbox?: string, limit = 500) {
  const q = new URLSearchParams();
  q.set('limit', String(limit));
  if (bbox) q.set('bbox', bbox);
  const r = await http<any>(`${base}/map/points?${q.toString()}`);
  return unwrap<any[]>(r, []);
}

/** DETAILS */
export async function catchById(id: string|number){ return await http<any>(`${base}/catch/${id}`); }
export async function placeById(id: string|number){ return await http<any>(`${base}/place/${id}`); }

/** INTERACTIONS */
export async function addCatchComment(id:number|string, text:string){
  return await http(`${base}/catch/${id}/comments`, {method:'POST', body:{text}});
}
export async function likeCatch(id:number|string){
  return await http(`${base}/catch/${id}/like`, {method:'POST'});
}

/** NOTIFICATIONS */
export async function notifications() {
  const r = await http<any>(`${base}/notifications`);
  return unwrap<any[]>(r, []);
}

/** PROFILE */
export async function profileMe(){ return await http<any>(`${base}/profile/me`); }

/** WEATHER FAVS (local) */
export function getWeatherFavs(): Array<{lat:number; lng:number; title?:string; id?:string|number}> {
  try {
    const raw = localStorage.getItem('weather_favs');
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}
export function saveWeatherFav(p: {lat:number; lng:number; title?:string}) {
  const list = getWeatherFavs();
  list.push(p);
  try { localStorage.setItem('weather_favs', JSON.stringify(list)); } catch {}
  return list;
}

/** ADD CATCH / PLACE */
export async function addCatch(payload: {
  species?: string; length?: number; weight?: number;
  style?: string; lure?: string; tackle?: string;
  notes?: string; photo_url?: string;
  lat?: number; lng?: number; caught_at?: string;
  privacy?: 'all'|'friends'|'private';
}) {
  return await http(`${base}/catch`, {method:'POST', body: payload});
}

export async function addPlace(payload: {
  title: string; description?: string;
  lat: number; lng: number;
  photos?: string[];
}) {
  return await http(`${base}/place`, {method:'POST', body: payload});
}

/** AUTH */
export async function login(email: string, password: string) {
  const r = await http<{token:string}>(`${base}/auth/login`, {method:'POST', body:{email,password}, auth:false});
  if (r?.token) localStorage.setItem('token', r.token);
  return r;
}
export async function register(name: string, email: string, password: string) {
  const r = await http<{token:string}>(`${base}/auth/register`, {method:'POST', body:{name,email,password}, auth:false});
  if (r?.token) localStorage.setItem('token', r.token);
  return r;
}
export function logout(){ try { localStorage.removeItem('token'); } catch {} }
export function isAuthed(){ return !!getToken(); }

/** RATINGS */
export async function rateCatch(catchId: string|number, stars: number){
  return await http(`${base}/catch/${catchId}/rating`, {method:'POST', body:{stars}});
}
export async function leaderboard(limit=20){
  const r = await http<any>(`${base}/leaderboard?limit=${limit}`);
  return unwrap<any[]>(r, []);
}

/** FRIENDS */
export async function friendsList(){
  const r = await http<any>(`${base}/friends`);
  return unwrap<any[]>(r, []);
}
export async function friendRequest(email: string){
  return await http(`${base}/friends/request`, {method:'POST', body:{email}});
}
export async function friendApprove(requestId: string|number){
  return await http(`${base}/friends/approve`, {method:'POST', body:{request_id:requestId}});
}
export async function friendRemove(userId: string|number){
  return await http(`${base}/friends/remove`, {method:'POST', body:{user_id:userId}});
}

/** BANNERS */
export async function bannersGet(slot: string){
  const r = await http<any>(`${base}/banners?slot=${encodeURIComponent(slot)}`);
  return unwrap<any[]>(r, []);
}

/** BONUSES */
export async function bonusBalance(){
  return await http<any>(`${base}/bonuses/balance`);
}
export async function bonusHistory(limit=50){
  const r = await http<any>(`${base}/bonuses/history?limit=${limit}`);
  return unwrap<any[]>(r, []);
}
/** Пример начисления за действие (like/share/add) — если бэк готов */
export async function bonusAward(action: 'like'|'share'|'add_catch'|'add_place', meta?: any){
  return await http<any>(`${base}/bonuses/award`, {method:'POST', body:{action, meta}});
}

/** SETTINGS */
export async function settingsGet(){
  return await http<any>(`${base}/settings`);
}
export async function settingsUpdate(patch: any){
  return await http<any>(`${base}/settings`, {method:'PATCH', body:patch});
}
TS

############################################
# 3) Общие компоненты: RatingStars, BannerSlot, Toast
############################################
cat > "$SRC/components/RatingStars.tsx" <<'TS'
import React, { useState } from 'react';
import Icon from './Icon';

const clamp = (n:number, a=1, b=5)=> Math.max(a, Math.min(b, n));

const RatingStars: React.FC<{
  value?: number;
  onChange?: (v:number)=>void;
  size?: number;
}> = ({value=0, onChange, size=22}) => {
  const [hover, setHover] = useState<number|null>(null);
  const v = clamp(Math.round(hover ?? value), 0, 5);
  return (
    <div className="row" role="radiogroup" aria-label="Оценка">
      {[1,2,3,4,5].map(i=>(
        <button
          key={i}
          type="button"
          className="btn"
          style={{padding:'6px 8px'}}
          aria-checked={v>=i}
          role="radio"
          onMouseEnter={()=>setHover(i)}
          onMouseLeave={()=>setHover(null)}
          onClick={()=> onChange?.(i)}
          title={`${i} из 5`}
        >
          <Icon name={v>=i? 'star':'star_rate'} size={size} />
        </button>
      ))}
    </div>
  );
};
export default RatingStars;
TS

cat > "$SRC/components/BannerSlot.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { bannersGet } from '../api';
import config from '../config';
import Icon from './Icon';

const BannerSlot: React.FC<{slot: string}> = ({slot}) => {
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    bannersGet(slot)
      .then(r => setItems(Array.isArray(r)? r : []))
      .catch(e => setErr(e.message||''));
  },[slot]);

  if (err) {
    // Тихо не мешаем UX, просто ничего не показываем
    return null;
  }
  const b = items[0];
  if (!b) return null;

  return (
    <a className="glass card" href={b.click_url || config.siteBase} target="_blank" rel="noreferrer" style={{display:'flex', gap:12, alignItems:'center'}}>
      <Icon name={config.icons.ad} />
      <div style={{flex:1}}>
        <div style={{fontWeight:600}}>{b.title || 'Реклама'}</div>
        {b.text && <div className="muted">{b.text}</div>}
      </div>
      {b.image_url && <img src={b.image_url} alt="" style={{width:64, height:64, objectFit:'cover', borderRadius:8}}/>}
    </a>
  );
};

export default BannerSlot;
TS

cat > "$SRC/components/Toast.tsx" <<'TS'
import React, { useEffect, useState } from 'react';

let pushImpl: ((msg:string)=>void) | null = null;
export function pushToast(msg:string){ pushImpl?.(msg); }

const ToastHost: React.FC = () => {
  const [list, setList] = useState<Array<{id:number; text:string}>>([]);
  useEffect(()=>{
    pushImpl = (text: string)=>{
      const id = Date.now() + Math.random();
      setList(prev => [...prev, {id, text}]);
      setTimeout(()=> setList(prev => prev.filter(x=>x.id!==id)), 3000);
    };
    return ()=>{ pushImpl = null; };
  },[]);
  return (
    <div style={{
      position:'fixed', left:0, right:0, bottom:86, display:'grid', gap:8,
      padding:'0 12px', pointerEvents:'none', zIndex:50
    }}>
      {list.map(i=>(
        <div key={i.id} className="glass card" style={{pointerEvents:'auto', justifySelf:'center'}}>
          {i.text}
        </div>
      ))}
    </div>
  );
};

export default ToastHost;
TS

############################################
# 4) Обновляем ленту: баннеры, рейтинг, бонусы
############################################
cat > "$SRC/pages/FeedScreen.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { feed, likeCatch, rateCatch, bonusAward } from '../api';
import Icon from '../components/Icon';
import config from '../config';
import { Link } from 'react-router-dom';
import RatingStars from '../components/RatingStars';
import BannerSlot from '../components/BannerSlot';
import { pushToast } from '../components/Toast';

const FeedScreen: React.FC = () => {
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    feed({limit:20, offset:0})
      .then((r)=> Array.isArray(r)? setItems(r) : setItems([]))
      .catch((e)=> setErr(e.message||'Ошибка загрузки ленты'));
  },[]);

  async function onLike(id:any){
    try{
      await likeCatch(id);
      pushToast('Лайк засчитан');
      // Попытка начислить бонус (если бэк поддерживает)
      bonusAward('like', {catch_id:id}).catch(()=>{});
    }catch(e:any){ pushToast(e?.message||'Ошибка'); }
  }
  async function onRate(id:any, stars:number){
    try{
      await rateCatch(id, stars);
      pushToast(`Оценка ${stars}/5 сохранена`);
      bonusAward('like', {kind:'rate', catch_id:id, stars}).catch(()=>{});
    }catch(e:any){ pushToast(e?.message||'Ошибка'); }
  }

  const spaced = [];
  const every = config.banners.feedEvery;
  for (let i=0;i<items.length;i++){
    spaced.push({kind:'post', data:items[i]});
    if ((i+1) % every === 0) spaced.push({kind:'banner', slot:`feed_${(i+1)/every}`});
  }

  return (
    <div className="container">
      <h2 className="h2">Лента</h2>
      {err && <div className="card glass" style={{color:'#ffb4b4'}}>{err}</div>}

      {(spaced.length? spaced : items.map(x=>({kind:'post', data:x}))).map((row:any, idx:number)=>{
        if (row.kind==='banner') return <BannerSlot key={`b-${idx}`} slot={row.slot} />;
        const it = row.data;
        return (
          <div key={it.id ?? idx} className="glass card">
            <div className="row" style={{justifyContent:'space-between'}}>
              <div className="row">
                <strong>{it.user_name || 'рыбак'}</strong>
                <span className="muted">· {new Date(it.created_at||Date.now()).toLocaleString()}</span>
              </div>
              <div className="row">
                <button className="btn" onClick={()=>onLike(it.id)}><Icon name={config.icons.like} /> {it.likes_count ?? 0}</button>
                <Link className="btn" to={`/catch/${it.id}`}><Icon name={config.icons.comment} /> {it.comments_count ?? 0}</Link>
                <button className="btn"><Icon name={config.icons.share} /> Поделиться</button>
              </div>
            </div>

            {it.media_url && <img src={it.media_url} alt="" style={{width:'100%', borderRadius:12, marginTop:8}} />}
            {it.caption && <div style={{marginTop:8}}>{it.caption}</div>}

            <div className="row" style={{marginTop:8, justifyContent:'space-between', alignItems:'center'}}>
              <div className="muted">Оцените улов</div>
              <RatingStars value={Math.round(it.rating_avg || 0)} onChange={(v)=>onRate(it.id, v)} />
            </div>
          </div>
        );
      })}
    </div>
  );
};
export default FeedScreen;
TS

############################################
# 5) Друзья, Настройки, Бонусы/Баланс, Лидерборд
############################################
cat > "$SRC/pages/FriendsPage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { friendsList, friendRequest, friendApprove, friendRemove } from '../api';

const FriendsPage: React.FC = () => {
  const [list, setList] = useState<any[]>([]);
  const [email, setEmail] = useState('');
  const [err, setErr] = useState('');

  async function reload(){
    try{
      const r = await friendsList();
      setList(Array.isArray(r)? r: []);
      setErr('');
    }catch(e:any){ setErr(e?.message||'Не удалось загрузить друзей'); }
  }
  useEffect(()=>{ reload(); },[]);

  async function sendReq(e:React.FormEvent){
    e.preventDefault();
    try{ await friendRequest(email); setEmail(''); reload(); }
    catch(e:any){ alert(e?.message||'Ошибка'); }
  }

  return (
    <div className="container">
      <h2 className="h2">Друзья</h2>
      <form className="glass card row" onSubmit={sendReq} style={{gap:8}}>
        <input className="input" placeholder="Email друга" value={email} onChange={e=>setEmail(e.target.value)} required />
        <button className="btn primary">Пригласить</button>
      </form>

      {err && <div className="card glass" style={{color:'#ffb4b4'}}>{err}</div>}

      <div className="grid" style={{marginTop:12}}>
        {list.map((f:any)=>(
          <div key={f.id} className="glass card row" style={{justifyContent:'space-between'}}>
            <div>
              <div style={{fontWeight:600}}>{f.name || f.email}</div>
              <div className="muted">{f.status || 'friend'}</div>
            </div>
            <div className="row">
              {f.request_id && f.status==='pending' && (
                <button className="btn" onClick={()=>friendApprove(f.request_id).then(reload)}>Принять</button>
              )}
              <button className="btn" onClick={()=>friendRemove(f.user_id || f.id).then(reload)}>Удалить</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
export default FriendsPage;
TS

cat > "$SRC/pages/SettingsPage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { settingsGet, settingsUpdate } from '../api';

const SettingsPage: React.FC = () => {
  const [data, setData] = useState<any>({});
  const [msg, setMsg] = useState('');

  useEffect(()=>{
    settingsGet().then(setData).catch(()=>setData({}));
  },[]);

  function set<K extends string>(k:K, v:any){ setData((s:any)=> ({...s, [k]:v})); }

  async function save(e:React.FormEvent){
    e.preventDefault(); setMsg('');
    try{
      await settingsUpdate(data);
      setMsg('Сохранено');
    }catch(e:any){ setMsg(e?.message||'Ошибка'); }
  }

  return (
    <div className="container">
      <h2 className="h2">Настройки профиля</h2>
      <form className="glass card grid" onSubmit={save}>
        <label>Никнейм</label>
        <input className="input" value={data.nickname||''} onChange={e=>set('nickname', e.target.value)} />
        <label>Приватность по умолчанию</label>
        <select className="select" value={data.default_privacy||'all'} onChange={e=>set('default_privacy', e.target.value)}>
          <option value="all">Все</option>
          <option value="friends">Друзья</option>
          <option value="private">Лично</option>
        </select>
        <button className="btn primary" type="submit">Сохранить</button>
        {msg && <div className="muted">{msg}</div>}
      </form>
    </div>
  );
};
export default SettingsPage;
TS

cat > "$SRC/pages/BonusesPage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { bonusBalance, bonusHistory } from '../api';
import Icon from '../components/Icon';
import config from '../config';

const BonusesPage: React.FC = () => {
  const [balance, setBalance] = useState<number>(0);
  const [list, setList] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    Promise.all([bonusBalance().catch(e=>{setErr(e.message||''); return {balance:0};}), bonusHistory().catch(()=>[])])
      .then(([b, h]: any)=> {
        setBalance(b?.balance ?? 0);
        setList(Array.isArray(h)? h: []);
      });
  },[]);

  return (
    <div className="container">
      <h2 className="h2">Бонусы</h2>
      {err && <div className="card glass" style={{color:'#ffb4b4'}}>{err}</div>}

      <div className="glass card row" style={{justifyContent:'space-between'}}>
        <div className="row"><Icon name={config.icons.gift} /> Текущий баланс</div>
        <div style={{fontWeight:700, fontSize:'1.25rem'}}>{balance}</div>
      </div>

      <h3 style={{marginTop:12}}>История</h3>
      <div className="grid">
        {list.map((i,idx)=>(
          <div key={idx} className="glass card row" style={{justifyContent:'space-between'}}>
            <div>
              <div style={{fontWeight:600}}>{i.title || i.action}</div>
              <div className="muted">{i.created_at ? new Date(i.created_at).toLocaleString(): ''}</div>
            </div>
            <div style={{fontWeight:700}}>{i.delta > 0 ? `+${i.delta}`: i.delta}</div>
          </div>
        ))}
        {list.length===0 && <div className="glass card">Записей нет</div>}
      </div>
    </div>
  );
};
export default BonusesPage;
TS

cat > "$SRC/pages/LeaderboardPage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import { leaderboard } from '../api';
import Icon from '../components/Icon';
import config from '../config';

const LeaderboardPage: React.FC = () => {
  const [list, setList] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    leaderboard(50).then(r=> setList(Array.isArray(r)? r: [])).catch(e=> setErr(e.message||''));
  },[]);

  return (
    <div className="container">
      <h2 className="h2">Лидерборд</h2>
      {err && <div className="glass card" style={{color:'#ffb4b4'}}>{err}</div>}

      <div className="grid">
        {list.map((u, idx)=>(
          <div key={u.user_id ?? idx} className="glass card row" style={{justifyContent:'space-between'}}>
            <div className="row">
              <Icon name={config.icons.leaderboard} />
              <strong style={{marginLeft:6}}>{u.name || `Участник #${u.user_id||idx+1}`}</strong>
            </div>
            <div className="muted">Очки: <b>{u.score ?? 0}</b></div>
          </div>
        ))}
        {list.length===0 && <div className="glass card">Нет данных</div>}
      </div>
    </div>
  );
};

export default LeaderboardPage;
TS

############################################
# 6) Обновляем MapScreen (кнопка тостов подключена уже)
############################################
cat > "$SRC/pages/MapScreen.tsx" <<'TS'
import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { points, saveWeatherFav } from '../api';
import { loadLeaflet } from '../utils/leafletLoader';
import PointPinCard from '../components/PointPinCard';
import Icon from '../components/Icon';
import config from '../config';
import { pushToast } from '../components/Toast';

const MapScreen: React.FC = () => {
  const nav = useNavigate();
  const mapRef = useRef<any>(null);
  const layerRef = useRef<any>(null);
  const [list, setList] = useState<any[]>([]);
  const [selected, setSelected] = useState<any|null>(null);
  const mapEl = useRef<HTMLDivElement>(null);

  useEffect(()=>{
    async function run(){
      try{
        const arr = await points(undefined, 500);
        setList(Array.isArray(arr)? arr : []);
      }catch(e){ console.error('points load error', e); }
    }
    run();
  },[]);

  useEffect(()=>{
    let map:any, L:any, markers:any;
    async function init(){
      if (!mapEl.current) return;
      L = await loadLeaflet();

      map = L.map(mapEl.current).setView([55.75, 37.62], 10);
      mapRef.current = map;

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',{
        attribution:'© OpenStreetMap',
      }).addTo(map);

      markers = L.layerGroup().addTo(map);
      layerRef.current = markers;

      map.on('click', (ev:any)=>{
        const { lat, lng } = ev.latlng;
        saveWeatherFav({lat, lng, title:`Выбранная точка`});
        pushToast('Точка добавлена в «Погоду»');
      });
    }
    init();
    return ()=>{ if (mapRef.current) mapRef.current.remove(); };
  },[]);

  useEffect(()=>{
    (async ()=>{
      const L = await loadLeaflet();
      const g = layerRef.current;
      if (!g) return;
      g.clearLayers();

      (Array.isArray(list) ? list : []).forEach((p:any)=>{
        const m = L.marker([p.lat, p.lng]).addTo(g);
        m.on('click', ()=> setSelected(p));
      });
    })();
  },[list]);

  return (
    <div className="container">
      <div className="row" style={{justifyContent:'space-between', marginBottom:8}}>
        <h2 className="h2">Карта</h2>
        <div className="row" style={{gap:6}}>
          <button className="btn" onClick={()=>nav('/add/place')} title="Добавить место">
            <Icon name={config.icons.add} /> Место
          </button>
          <button className="btn" onClick={()=>nav('/add/catch')} title="Добавить улов">
            <Icon name={config.icons.add} /> Улов
          </button>
        </div>
      </div>

      <div ref={mapEl} className="leaflet-container glass" />

      {selected && (
        <div style={{marginTop:12}}>
          <PointPinCard p={{
            id: selected.id,
            lat: selected.lat,
            lng: selected.lng,
            title: selected.title || selected.name,
            photos: selected.photos,
            kind: selected.type || 'place'
          }}/>
        </div>
      )}
    </div>
  );
};
export default MapScreen;
TS

############################################
# 7) Обновляем ProfilePage: ссылки на новые разделы
############################################
cat > "$SRC/pages/ProfilePage.tsx" <<'TS'
import React, { useEffect, useState } from 'react';
import config from '../config';
import { profileMe, isAuthed, logout } from '../api';
import { Link } from 'react-router-dom';
import Icon from '../components/Icon';

const ProfilePage: React.FC = () => {
  const [me, setMe] = useState<any>(null);
  const [err, setErr] = useState<string>('');

  useEffect(() => {
    if (!isAuthed()) {
      setErr('Требуется вход в систему.');
      return;
    }
    profileMe()
      .then(setMe)
      .catch((e) => setErr(e.message || 'Не удалось загрузить профиль'));
  }, []);

  const avatar = me?.photo_url || config?.images?.defaultAvatar || '/assets/default-avatar.png';

  return (
    <div className="container">
      <div className="glass card" style={{display:'flex', gap:12, alignItems:'center'}}>
        <img src={avatar} alt="avatar" style={{width:64, height:64, borderRadius:'50%', objectFit:'cover'}} />
        <div style={{flex:1}}>
          <div style={{fontWeight:600}}>{me?.name || '—'}</div>
          <div className="muted">{me?.email || ''}</div>
        </div>
        {isAuthed() && (
          <button className="btn" onClick={()=>{ logout(); location.href='/login'; }}>Выйти</button>
        )}
      </div>
      {err && <div className="card glass" style={{color:'#ffb4b4', marginTop:10}}>{err}</div>}

      <div className="grid" style={{marginTop:12}}>
        <Link to="/friends" className="glass card row" style={{justifyContent:'space-between'}}>
          <div className="row"><Icon name={config.icons.friends} /> Друзья</div>
          <Icon name="chevron_right" />
        </Link>
        <Link to="/bonuses" className="glass card row" style={{justifyContent:'space-between'}}>
          <div className="row"><Icon name={config.icons.gift} /> Бонусы и история</div>
          <Icon name="chevron_right" />
        </Link>
        <Link to="/leaderboard" className="glass card row" style={{justifyContent:'space-between'}}>
          <div className="row"><Icon name={config.icons.leaderboard} /> Лидерборд</div>
          <Icon name="chevron_right" />
        </Link>
        <Link to="/settings" className="glass card row" style={{justifyContent:'space-between'}}>
          <div className="row"><Icon name={config.icons.settings} /> Настройки профиля</div>
          <Icon name="chevron_right" />
        </Link>
      </div>
    </div>
  );
};

export default ProfilePage;
TS

############################################
# 8) WeatherPage — без изменений логики, лишь сохраняем совместимость (оставим как есть)
############################################
cat > "$SRC/pages/WeatherPage.tsx" <<'TS'
import React from 'react';
import { getWeatherFavs } from '../api';

const WeatherPage: React.FC = () => {
  const favs = getWeatherFavs();
  const list = Array.isArray(favs) ? favs : [];

  return (
    <div className="container">
      <h2 className="h2">Погода</h2>
      {list.length === 0 ? (
        <div className="muted glass card">Пока ни одной избранной точки. Нажмите по карте, чтобы добавить.</div>
      ) : (
        <ul className="grid" style={{listStyle:'none', padding:0}}>
          {list.map((p, idx) => (
            <li key={idx} className="card glass">
              <div style={{fontWeight:600}}>{p.title || `Точка (${p.lat.toFixed(4)}, ${p.lng.toFixed(4)})`}</div>
              <div className="muted">температура: — / ветер: —</div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
};

export default WeatherPage;
TS

############################################
# 9) AppRoot.tsx — добавляем новые маршруты + ToastHost
############################################
cat > "$SRC/AppRoot.tsx" <<'TS'
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';

import Header from './components/Header';
import BottomNav from './components/BottomNav';
import ToastHost from './components/Toast';

import FeedScreen from './pages/FeedScreen';
import MapScreen from './pages/MapScreen';
import AddCatchPage from './pages/AddCatchPage';
import AddPlacePage from './pages/AddPlacePage';
import NotificationsPage from './pages/NotificationsPage';
import ProfilePage from './pages/ProfilePage';
import WeatherPage from './pages/WeatherPage';
import CatchDetailPage from './pages/CatchDetailPage';
import PlaceDetailPage from './pages/PlaceDetailPage';

import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import FriendsPage from './pages/FriendsPage';
import SettingsPage from './pages/SettingsPage';
import BonusesPage from './pages/BonusesPage';
import LeaderboardPage from './pages/LeaderboardPage';
import { isAuthed } from './api';

const ProtectedRoute: React.FC<{ children: React.ReactElement }> = ({ children }) => {
  if (!isAuthed()) return <Navigate to="/login" replace />;
  return children;
};

const AppRoot: React.FC = () => {
  return (
    <BrowserRouter>
      <div className="app-shell">
        <Header />
        <main className="app-main">
          <Routes>
            <Route path="/" element={<Navigate to="/feed" replace />} />
            <Route path="/feed" element={<FeedScreen />} />
            <Route path="/map" element={<MapScreen />} />
            <Route path="/catch/:id" element={<CatchDetailPage />} />
            <Route path="/place/:id" element={<PlaceDetailPage />} />
            <Route path="/weather" element={<WeatherPage />} />
            <Route path="/alerts" element={<NotificationsPage />} />

            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />

            <Route path="/add/catch" element={<ProtectedRoute><AddCatchPage /></ProtectedRoute>} />
            <Route path="/add/place" element={<ProtectedRoute><AddPlacePage /></ProtectedRoute>} />
            <Route path="/profile" element={<ProtectedRoute><ProfilePage /></ProtectedRoute>} />

            <Route path="/friends" element={<ProtectedRoute><FriendsPage /></ProtectedRoute>} />
            <Route path="/settings" element={<ProtectedRoute><SettingsPage /></ProtectedRoute>} />
            <Route path="/bonuses" element={<ProtectedRoute><BonusesPage /></ProtectedRoute>} />
            <Route path="/leaderboard" element={<LeaderboardPage />} />

            <Route path="*" element={<Navigate to="/feed" replace />} />
          </Routes>
        </main>
        <BottomNav />
      </div>
      <ToastHost />
      <style>{`
        .app-shell { min-height: 100svh; display: grid; grid-template-rows: auto 1fr auto; }
        .app-main { min-height: 0; }
      `}</style>
    </BrowserRouter>
  );
};

export default AppRoot;
TS

############################################
# 10) Обновляем Header/BottomNav (совместимость) — уже ок, но перезапишем на всякий
############################################
cat > "$SRC/components/Header.tsx" <<'TS'
import React from 'react';
import { Link } from 'react-router-dom';
import config from '../config';
import Icon from './Icon';

const Header: React.FC = () => {
  const logo = config?.images?.logoUrl || '/src/assets/logo.svg';
  return (
    <header className="header glass">
      <div className="left">
        <Link to="/feed" className="row" aria-label="На главную">
          <img src={logo} alt="Logo" style={{height:28}} />
        </Link>
      </div>
      <div className="right">
        <Link to="/weather" className="btn" title="Погода">
          <Icon name={config.icons.weather} /> <span className="hide-sm">Погода</span>
        </Link>
        <Link to="/add/catch" className="btn primary" title="Добавить улов">
          <Icon name={config.icons.add} /> <span className="hide-sm">Улов</span>
        </Link>
      </div>
    </header>
  );
};

export default Header;
TS

cat > "$SRC/components/BottomNav.tsx" <<'TS'
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';
import Icon from './Icon';

const BottomNav: React.FC = () => {
  const { pathname } = useLocation();
  const is = (p: string) => pathname.startsWith(p);
  const Item: React.FC<{to:string; icon:string; label:string}> = ({to, icon, label}) => (
    <Link to={to} className={`bottom-link glass ${is(to)?'active':''}`}>
      <Icon name={icon} />
      <small>{label}</small>
    </Link>
  );
  return (
    <nav className="bottom-nav glass">
      <Item to="/feed" icon={config.icons.home} label="Лента" />
      <Item to="/map" icon={config.icons.map} label="Карта" />
      <Item to="/add/place" icon={config.icons.add} label="Место" />
      <Item to="/alerts" icon={config.icons.alerts} label="Оповещения" />
      <Item to="/profile" icon={config.icons.profile} label="Профиль" />
    </nav>
  );
};

export default BottomNav;
TS

echo "✅ Sprint 2 front updates applied."
echo "Теперь: npm i && npm run build"