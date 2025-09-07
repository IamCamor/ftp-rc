#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"

say() { printf "• %s\n" "$*"; }
ok()  { printf "✅ %s\n" "$*"; }
warn(){ printf "⚠️  %s\n" "$*"; }

# 0) Проверки наличия src
test -d "$ROOT/frontend/src" || { echo "Не найден каталог frontend/src"; exit 1; }

###############################################################################
# 1) CONFIG: featureFlags
###############################################################################
CFG="$ROOT/frontend/src/config.ts"
if [ -f "$CFG" ]; then
  cp "$CFG" "$CFG.bak"
  say "Бэкап config.ts → config.ts.bak"

  if ! grep -q "export const featureFlags" "$CFG"; then
    cat >> "$CFG" <<'EOF'

// --- auto-added feature flags ---
export const featureFlags = {
  requireAuthForWeatherSave: true,
  oauth: {
    google: true,
    vk: true,
    yandex: true,
    apple: true,
  },
  banners: true,
  ratings: true,
  bonuses: true,
};
EOF
    ok "Добавлены featureFlags в config.ts (named export)"
  else
    say "featureFlags уже присутствуют в config.ts — пропускаю вставку"
  fi
else
  warn "config.ts не найден — пропускаю шаг featureFlags"
fi

###############################################################################
# 2) PAGE: MapScreen.tsx (карта + безопасный доступ к флагам + сохранение погоды)
###############################################################################
MAP="$ROOT/frontend/src/pages/MapScreen.tsx"
mkdir -p "$(dirname "$MAP")"
cat > "$MAP" <<'EOF'
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
EOF
ok "Пересобран MapScreen.tsx"

###############################################################################
# 3) PAGE: WeatherPage.tsx (устойчиво к не-массиву)
###############################################################################
WEA="$ROOT/frontend/src/pages/WeatherPage.tsx"
mkdir -p "$(dirname "$WEA")"
cat > "$WEA" <<'EOF'
import React, { useEffect, useState } from 'react';
import config from '../config';
import Icon from '../components/Icon';

type Fav = { lat:number; lng:number; name?:string };

export default function WeatherPage(){
  const [favs, setFavs] = useState<Fav[]>([]);

  useEffect(() => {
    try{
      const raw = localStorage.getItem('weatherFavs');
      const parsed = raw ? JSON.parse(raw) : [];
      const arr = Array.isArray(parsed) ? parsed : [];
      setFavs(arr.filter(v => typeof v?.lat==='number' && typeof v?.lng==='number'));
    } catch{
      setFavs([]);
    }
  }, []);

  if (!favs.length){
    return (
      <div style={{padding:16}}>
        <div style={{
          backdropFilter:'blur(10px)',
          background:'rgba(255,255,255,0.35)',
          border:'1px solid rgba(255,255,255,0.4)',
          borderRadius:16,
          padding:16
        }}>
          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:8}}>
            <Icon name="cloud" />
            <b>Погода</b>
          </div>
          <div>У вас пока нет сохранённых точек. Откройте Карту и кликните по месту, чтобы сохранить точку.</div>
        </div>
      </div>
    );
  }

  return (
    <div style={{padding:16, display:'grid', gap:12}}>
      {favs.map((f, i) => (
        <div key={i} style={{
          backdropFilter:'blur(10px)',
          background:'rgba(255,255,255,0.35)',
          border:'1px solid rgba(255,255,255,0.4)',
          borderRadius:16, padding:16
        }}>
          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:6}}>
            <Icon name="place" />
            <b>{f.name || `Точка ${i+1}`}</b>
          </div>
          <div style={{fontSize:14,opacity:.8}}>Координаты: {f.lat.toFixed(5)}, {f.lng.toFixed(5)}</div>
          {/* Здесь можно подставить виджет прогноза или запрос на ваш бек */}
        </div>
      ))}
    </div>
  );
}
EOF
ok "Пересобран WeatherPage.tsx"

###############################################################################
# 4) PAGE: ProfilePage.tsx (безопасный доступ к конфигу/аватару, выход)
###############################################################################
PROF="$ROOT/frontend/src/pages/ProfilePage.tsx"
mkdir -p "$(dirname "$PROF")"
cat > "$PROF" <<'EOF'
import React, { useEffect, useState } from 'react';
import config from '../config';
import { profileMe, isAuthed, logout } from '../api';
import { Link, useNavigate } from 'react-router-dom';
import Icon from '../components/Icon';

type Me = {
  id:number|string;
  name?:string;
  login?:string;
  avatar?:string;
  photoUrl?:string;
  rating?:number;
  email?:string;
};

export default function ProfilePage(){
  const [me, setMe] = useState<Me | null>(null);
  const [authed, setAuthed] = useState<boolean>(false);
  const navigate = useNavigate();

  useEffect(() => {
    (async () => {
      const ok = await isAuthed();
      setAuthed(!!ok);
      if (ok) {
        try { setMe(await profileMe()); } catch { setMe(null); }
      }
    })();
  }, []);

  const avatar = me?.photoUrl || me?.avatar || (config as any)?.assets?.defaultAvatar || '/assets/default-avatar.png';

  if (!authed){
    return (
      <div style={{padding:16}}>
        <div style={{
          backdropFilter:'blur(10px)',
          background:'rgba(255,255,255,0.35)',
          border:'1px solid rgba(255,255,255,0.4)',
          borderRadius:16, padding:16
        }}>
          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:8}}>
            <Icon name="person" />
            <b>Профиль</b>
          </div>
          <div style={{marginBottom:12}}>Вы не авторизованы.</div>
          <div style={{display:'flex',gap:8}}>
            <Link to="/login" style={{padding:'8px 12px',borderRadius:10,background:'#0ea5e9',color:'#fff',textDecoration:'none'}}>Войти</Link>
            <Link to="/register" style={{padding:'8px 12px',borderRadius:10,background:'#111827',color:'#fff',textDecoration:'none'}}>Регистрация</Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div style={{padding:16, display:'grid', gap:12}}>
      <div style={{
        display:'flex', gap:12, alignItems:'center',
        backdropFilter:'blur(10px)',
        background:'rgba(255,255,255,0.35)',
        border:'1px solid rgba(255,255,255,0.4)',
        borderRadius:16, padding:16
      }}>
        <img src={avatar} alt="avatar" style={{width:64,height:64,borderRadius:'50%',objectFit:'cover'}} />
        <div>
          <div style={{fontWeight:700}}>{me?.name || me?.login || 'Пользователь'}</div>
          <div style={{fontSize:13,opacity:.8}}>{me?.email || ''}</div>
          {!!me?.rating && <div style={{fontSize:13,marginTop:4}}><Icon name="star" /> Рейтинг: {me.rating}</div>}
        </div>
      </div>

      <div style={{
        display:'flex', gap:8, flexWrap:'wrap'
      }}>
        <Link to="/profile/edit" style={{padding:'8px 12px',borderRadius:10,background:'#f3f4f6',textDecoration:'none'}}>Настройки профиля</Link>
        <Link to="/bonuses" style={{padding:'8px 12px',borderRadius:10,background:'#f3f4f6',textDecoration:'none'}}>Бонусы</Link>
        <Link to="/privacy" style={{padding:'8px 12px',borderRadius:10,background:'#f3f4f6',textDecoration:'none'}}>Конфиденциальность</Link>
      </div>

      <button
        onClick={async () => { try { await logout(); } catch {} navigate('/'); }}
        style={{padding:'10px 14px',borderRadius:12,background:'#ef4444',color:'#fff',border:0,cursor:'pointer',width:'fit-content'}}
      >
        Выйти
      </button>
    </div>
  );
}
EOF
ok "Пересобран ProfilePage.tsx"

echo
ok "Патчи применены. Сборка:"
echo "   cd frontend && npm run build"
echo
echo "Если карта всё ещё не видна — проверьте CSP/прокси и что на странице нет перекрывающих контейнеров."