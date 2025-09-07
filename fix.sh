#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
FILE="$ROOT/frontend/src/pages/PlaceDetailPage.tsx"

mkdir -p "$(dirname "$FILE")"

cat > "$FILE" <<'EOF'
import React, { useEffect, useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import config from '../config';
import Icon from '../components/Icon';

type Media = { url: string; width?: number; height?: number };
type Place = {
  id: number | string;
  title?: string;
  description?: string;
  lat?: number;
  lng?: number;
  photos?: Media[];       // ожидаем, что бэк вернёт массив фоток (если есть)
  catches?: Array<{ id: number|string; thumbnail?: string }>;
};

export default function PlaceDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [place, setPlace] = useState<Place | null>(null);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    let abort = false;
    (async () => {
      if (!id) return;
      setLoading(true); setErr(null);
      try {
        const base = (config as any)?.apiBase ?? '';
        const res = await fetch(`${base}/map/points/${id}`, {
          credentials: 'include',
          headers: { 'Accept': 'application/json' }
        });
        if (!res.ok) {
          throw new Error(`HTTP ${res.status}`);
        }
        const data = await res.json();
        // Поддержим варианты формата ответа:
        // 1) напрямую объект места
        // 2) { data: {...} }
        const p: Place = (data && typeof data === 'object' && data.data) ? data.data : data;
        if (!abort) setPlace(p);
      } catch (e: any) {
        if (!abort) setErr(e?.message || 'Failed to load place');
      } finally {
        if (!abort) setLoading(false);
      }
    })();
    return () => { abort = true; };
  }, [id]);

  if (loading) {
    return (
      <div style={{padding:16}}>
        <div style={cardStyle}>
          <div style={titleRow}><Icon name="place" /><b>Место</b></div>
          <div>Загрузка...</div>
        </div>
      </div>
    );
  }

  if (err || !place) {
    return (
      <div style={{padding:16}}>
        <div style={cardStyle}>
          <div style={titleRow}><Icon name="place" /><b>Место</b></div>
          <div style={{color:'#ef4444', marginBottom:10}}>
            Не удалось загрузить место{err ? `: ${err}` : ''}.
          </div>
          <button onClick={() => navigate(-1)} style={btnPrimary}>
            <Icon name="arrow_back" /> Назад
          </button>
        </div>
      </div>
    );
  }

  const photos = Array.isArray(place.photos) ? place.photos : [];
  const catches = Array.isArray(place.catches) ? place.catches : [];

  return (
    <div style={{padding:16, display:'grid', gap:12}}>
      <div style={cardStyle}>
        <div style={titleRow}><Icon name="place" /><b>{place.title || `Место #${place.id}`}</b></div>
        {place.description && (
          <div style={{margin:'8px 0 4px'}}>{place.description}</div>
        )}
        {(typeof place.lat === 'number' && typeof place.lng === 'number') && (
          <div style={{fontSize:13, opacity:.8}}>
            Координаты: {place.lat.toFixed(5)}, {place.lng.toFixed(5)}
          </div>
        )}
      </div>

      {photos.length > 0 && (
        <div style={cardStyle}>
          <div style={titleRow}><Icon name="photo_library" /><b>Фотографии</b></div>
          <div style={grid}>
            {photos.map((ph, i) => (
              <button
                key={i}
                onClick={() => window.open(ph.url, '_blank')}
                style={thumbBtn}
                title="Открыть фото"
              >
                <img src={ph.url} alt={`photo-${i}`}
                     style={{width:'100%',height:'100%',objectFit:'cover',borderRadius:12}} />
              </button>
            ))}
          </div>
        </div>
      )}

      {catches.length > 0 && (
        <div style={cardStyle}>
          <div style={titleRow}><Icon name="emoji_nature" /><b>Уловы</b></div>
          <div style={grid}>
            {catches.map((c) => (
              <Link
                key={String(c.id)}
                to={`/catch/${c.id}`}
                style={thumbBtn}
                title="Открыть улов"
              >
                {c.thumbnail
                  ? <img src={c.thumbnail} style={{width:'100%',height:'100%',objectFit:'cover',borderRadius:12}} />
                  : <div style={thumbFallback}><Icon name="image_not_supported" /></div>
                }
              </Link>
            ))}
          </div>
        </div>
      )}

      <div style={{display:'flex',gap:8,flexWrap:'wrap'}}>
        <Link to={`/map`} style={btnSecondary}><Icon name="map" /> На карту</Link>
        <Link to={`/weather`} style={btnSecondary}><Icon name="cloud" /> Погода</Link>
      </div>
    </div>
  );
}

/** UI helpers (glassmorphism) */
const cardStyle: React.CSSProperties = {
  backdropFilter:'blur(10px)',
  background:'rgba(255,255,255,0.35)',
  border:'1px solid rgba(255,255,255,0.4)',
  borderRadius:16,
  padding:16
};

const titleRow: React.CSSProperties = {
  display:'flex',
  alignItems:'center',
  gap:8,
  marginBottom:8
};

const grid: React.CSSProperties = {
  display:'grid',
  gridTemplateColumns:'repeat(3, 1fr)',
  gap:10
};

const thumbBtn: React.CSSProperties = {
  width:'100%',
  aspectRatio:'1 / 1',
  border:0,
  padding:0,
  borderRadius:12,
  overflow:'hidden',
  cursor:'pointer',
  background:'transparent'
};

const thumbFallback: React.CSSProperties = {
  width:'100%',
  height:'100%',
  display:'grid',
  placeItems:'center',
  borderRadius:12,
  background:'#f3f4f6'
};

const btnPrimary: React.CSSProperties = {
  display:'inline-flex',
  alignItems:'center',
  gap:6,
  padding:'10px 14px',
  borderRadius:12,
  background:'#0ea5e9',
  color:'#fff',
  border:0,
  cursor:'pointer'
};

const btnSecondary: React.CSSProperties = {
  display:'inline-flex',
  alignItems:'center',
  gap:6,
  padding:'10px 14px',
  borderRadius:12,
  background:'#f3f4f6',
  color:'#111827',
  textDecoration:'none'
};
EOF

echo "✅ PlaceDetailPage.tsx обновлён: теперь запрашивает /api/v1/map/points/:id"