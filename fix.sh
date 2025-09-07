#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"

# 1) Обновляем config.ts — добавляем ui.feedEvery с дефолтом
cat > "$ROOT/frontend/src/config.ts" <<'TS'
const config = {
  apiBase: (import.meta as any).env?.VITE_API_BASE ?? 'https://api.fishtrackpro.ru/api/v1',
  siteBase: (import.meta as any).env?.VITE_SITE_BASE ?? 'https://www.fishtrackpro.ru',
  assets: {
    logoUrl: '/logo.svg',
    defaultAvatar: '/default-avatar.png',
  },
  ui: {
    // период авто-обновления ленты в мс (можно отключить = 0)
    feedEvery: 60000,
  },
  flags: {
    glass: true,
    authPasswordEnabled: false,
    authOAuthEnabled: true,
    notificationsEnabled: false,
    profileEnabled: false,
    requireAuthForWeatherSave: false,
  },
  legal: {
    privacyConsentUrl: '/legal/privacy',
    offerUrl: '/legal/offer',
    rulesUrl: '/legal/rules',
  },
  providers: {
    google:  { enabled: true,  path: '/auth/google/redirect' },
    vk:      { enabled: true,  path: '/auth/vk/redirect' },
    yandex:  { enabled: true,  path: '/auth/yandex/redirect' },
    apple:   { enabled: true,  path: '/auth/apple/redirect' },
  },
  banners: {
    enabled: true,
    slots: ['feed.top','feed.bottom','map.bottom'],
  },
};
export default config;
TS

# 2) Чиним FeedScreen.tsx — безопасная работа без падений и с авто-обновлением
cat > "$ROOT/frontend/src/pages/FeedScreen.tsx" <<'TS'
import React, { useEffect, useMemo, useRef, useState } from 'react';
import AppShell from '../components/AppShell';
import Icon from '../components/Icon';
import config from '../config';
import { feed, likeCatch, rateCatch, bonusAward } from '../api';

type FeedItem = {
  id: number|string;
  user?: { name?: string; avatar?: string };
  title?: string;
  text?: string;
  media?: string[];
  likes?: number;
  rating?: number;
  created_at?: string;
};

export default function FeedScreen(){
  const [items, setItems] = useState<FeedItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string|null>(null);
  const refreshMs = useMemo(()=> {
    const v = (config as any)?.ui?.feedEvery;
    return typeof v === 'number' && v >= 0 ? v : 60000;
  }, []);
  const timer = useRef<number|undefined>(undefined);

  async function load(reset=false){
    setErr(null);
    if (loading) return;
    setLoading(true);
    try{
      const data = await feed(10, reset ? 0 : items.length);
      const list = Array.isArray((data as any)?.items) ? (data as any).items
                 : Array.isArray(data) ? data
                 : [];
      setItems(prev => reset ? list : [...prev, ...list]);
    }catch(e:any){
      setErr(e?.message ?? 'Не удалось загрузить ленту');
    }finally{
      setLoading(false);
    }
  }

  useEffect(()=>{
    load(true);
    if (refreshMs > 0){
      timer.current = window.setInterval(()=> load(true), refreshMs);
    }
    return ()=> { if (timer.current) window.clearInterval(timer.current); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const onLike = async (id: number|string)=>{
    try{
      await likeCatch(id);
      setItems(prev => prev.map(it => it.id===id ? {...it, likes: (it.likes ?? 0)+1} : it));
      await bonusAward('like', { id });
    }catch{}
  };

  const onRate = async (id: number|string, stars:number)=>{
    try{
      await rateCatch(id, stars);
      setItems(prev => prev.map(it => it.id===id ? {...it, rating: stars} : it));
      await bonusAward('rate', { id, stars });
    }catch{}
  };

  return (
    <AppShell>
      <div className="glass card" style={{display:'grid',gap:12}}>
        <div className="row" style={{justifyContent:'space-between'}}>
          <div className="row"><Icon name="home" /><b>Лента</b></div>
          <button className="btn ghost" onClick={()=>load(true)} disabled={loading}>
            <Icon name="refresh" /> Обновить
          </button>
        </div>

        {err && <div className="help">{err}</div>}

        {!err && items.length===0 && !loading && (
          <div className="help">Пока нет записей. Попробуйте позже.</div>
        )}

        <div style={{display:'grid', gap:12}}>
          {items.map(it=>(
            <div key={String(it.id)} className="glass card" style={{padding:12}}>
              <div className="row" style={{gap:10}}>
                <img src={it.user?.avatar ?? '/default-avatar.png'} alt="" style={{width:40,height:40,borderRadius:12}}/>
                <div>
                  <b>{it.user?.name ?? 'Аноним'}</b>
                  <div className="help">{it.created_at ? new Date(it.created_at).toLocaleString() : ''}</div>
                </div>
              </div>
              {it.title && <div style={{marginTop:8}}><b>{it.title}</b></div>}
              {it.text && <div style={{marginTop:6}}>{it.text}</div>}
              {Array.isArray(it.media) && it.media.length>0 && (
                <div className="grid-3" style={{marginTop:8}}>
                  {it.media.slice(0,3).map((m,idx)=>(
                    <img key={idx} src={m} alt="" style={{width:'100%',height:100,objectFit:'cover',borderRadius:12}} />
                  ))}
                </div>
              )}

              <div className="row" style={{gap:8, marginTop:10}}>
                <button className="btn ghost" onClick={()=>onLike(it.id)}><Icon name="favorite" /> {(it.likes??0)}</button>
                <button className="btn ghost" onClick={()=>onRate(it.id, 5)}><Icon name="star" /> {(it.rating??0)}</button>
                <a className="btn ghost" href={`/catch/${it.id}`}><Icon name="open_in_new" /> Открыть</a>
              </div>
            </div>
          ))}
        </div>

        <div className="row" style={{justifyContent:'center', marginTop:4}}>
          <button className="btn primary" onClick={()=>load(false)} disabled={loading}>
            <Icon name="expand_more" /> Ещё
          </button>
        </div>
      </div>
    </AppShell>
  );
}
TS

echo "✅ Патч применён. Соберите проект: cd frontend && npm run build && npm run preview"