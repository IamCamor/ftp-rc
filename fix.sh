#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
BACK="$ROOT/backend"
FRONT="$ROOT/frontend"

echo "==> Writing backend controllers..."

mkdir -p "$BACK/app/Http/Controllers/Api"

# FeedController
cat > "$BACK/app/Http/Controllers/Api/FeedController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class FeedController extends Controller
{
    public function index(Request $r)
    {
        $limit  = min(max((int)$r->query('limit', 20), 1), 50);
        $offset = max((int)$r->query('offset', 0), 0);
        $q      = trim((string)$r->query('q', ''));
        $tab    = strtolower((string)$r->query('tab', 'global')); // global|local|follow
        $lat    = $r->query('lat');
        $lng    = $r->query('lng');
        $radius = (float)$r->query('radius_km', 50); // для tab=local

        // Безопасные выражения под фактическую схему
        $commentsExpr = Schema::hasColumn('catch_comments','is_approved')
            ? '(select count(*) from catch_comments cc where cc.catch_id = cr.id and cc.is_approved = 1)'
            : '(select count(*) from catch_comments cc where cc.catch_id = cr.id)';

        $placeExpr = Schema::hasTable('fishing_points')
            ? "(select fp.title from fishing_points fp where (fp.status = 'approved' or fp.status is null)
                order by POW(fp.lat - cr.lat, 2) + POW(fp.lng - cr.lng, 2) asc limit 1)"
            : "NULL";

        $select = [
            'cr.id','cr.user_id','u.name as user_name',
            DB::raw(Schema::hasColumn('users','photo_url') ? 'u.photo_url as user_avatar' : 'NULL as user_avatar'),
            'cr.lat','cr.lng','cr.species','cr.length','cr.weight','cr.style','cr.lure','cr.tackle','cr.notes',
            'cr.photo_url','cr.caught_at','cr.created_at',
            DB::raw('(select count(*) from catch_likes cl where cl.catch_id = cr.id) as likes_count'),
            DB::raw("$commentsExpr as comments_count"),
            DB::raw("$placeExpr as place_title"),
            DB::raw('0 as liked_by_me')
        ];

        $qbase = DB::table('catch_records as cr')
            ->leftJoin('users as u', 'u.id', '=', 'cr.user_id')
            ->whereIn('cr.privacy', ['all','public','everyone']);

        if ($q !== '') {
            $qbase->where(function($w) use ($q){
                $w->where('cr.species','like',"%{$q}%")
                  ->orWhere('cr.lure','like',"%{$q}%")
                  ->orWhere('cr.tackle','like',"%{$q}%")
                  ->orWhere('cr.notes','like',"%{$q}%")
                  ->orWhere('u.name','like',"%{$q}%");
            });
        }

        if ($tab === 'local' && is_numeric($lat) && is_numeric($lng)) {
            $lat = (float)$lat; $lng = (float)$lng;
            $delta = max($radius, 1.0) / 111.0; // ~1° = 111км
            $minLat = $lat - $delta; $maxLat = $lat + $delta;
            $minLng = $lng - $delta; $maxLng = $lng + $delta;
            $qbase->whereBetween('cr.lat', [$minLat, $maxLat])
                  ->whereBetween('cr.lng', [$minLng, $maxLng]);
        } elseif ($tab === 'follow') {
            // Если авторизации нет — просто не фильтруем дополнительно (или верните пусто по желанию)
            if (auth()->check() && Schema::hasTable('follows')) {
                $uid = auth()->id();
                $qbase->whereIn('cr.user_id', function($sub) use ($uid) {
                    $sub->from('follows')->select('followee_id')->where('follower_id', $uid);
                });
            }
        }

        $items = $qbase->orderByDesc('cr.created_at')->offset($offset)->limit($limit)->get($select);

        return response()->json([
            'items'  => $items,
            'limit'  => $limit,
            'offset' => $offset,
            'next'   => count($items) === $limit ? $offset + $limit : null,
        ]);
    }

    // Публичные комментарии по улову (для отображения списка по клику)
    public function comments($id, Request $r)
    {
        $limit  = min(max((int)$r->query('limit', 20), 1), 100);
        $offset = max((int)$r->query('offset', 0), 0);

        $q = DB::table('catch_comments as c')
            ->leftJoin('users as u','u.id','=','c.user_id')
            ->where('c.catch_id',$id);

        if (Schema::hasColumn('catch_comments','is_approved')) {
            $q->where('c.is_approved', 1);
        }

        $rows = $q->orderBy('c.created_at','asc')
            ->offset($offset)->limit($limit)
            ->get([
                'c.id','c.user_id','u.name as user_name',
                DB::raw(Schema::hasColumn('users','photo_url') ? 'u.photo_url as user_avatar' : 'NULL as user_avatar'),
                'c.body','c.created_at'
            ]);

        return response()->json([
            'items'  => $rows,
            'limit'  => $limit,
            'offset' => $offset,
            'next'   => count($rows)===$limit ? $offset+$limit : null,
        ]);
    }
}
PHP

echo "==> Patching routes..."

ROUTES="$BACK/routes/api.php"
if ! grep -q "FeedController" "$ROUTES"; then
  # Вставим блок v1/feed и комментарии
  cat >> "$ROUTES" <<'PHP'

// --- FEED API (safe to schema) ---
use App\Http\Controllers\Api\FeedController;
Route::prefix('v1')->group(function () {
    Route::get('/feed', [FeedController::class,'index']);               // GET /api/v1/feed
    Route::get('/catches/{id}/comments', [FeedController::class,'comments']); // GET /api/v1/catches/{id}/comments
});
PHP
fi

echo "==> Backend done."

echo "==> Writing frontend files..."

mkdir -p "$FRONT/src/types" "$FRONT/src/components" "$FRONT/src/screens" "$FRONT/src/lib"

# types
cat > "$FRONT/src/types/feed.ts" <<'TS'
export type FeedItem = {
  id: number;
  user_id: number | null;
  user_name?: string | null;
  user_avatar?: string | null;
  species?: string | null;
  length?: number | null;
  weight?: number | null;
  style?: string | null;
  lure?: string | null;
  tackle?: string | null;
  notes?: string | null;
  photo_url?: string | null;
  lat: number;
  lng: number;
  caught_at?: string | null;
  created_at?: string | null;
  likes_count: number;
  comments_count: number;
  place_title?: string | null;
};
TS

# lib/api base
cat > "$FRONT/src/lib/api.ts" <<'TS'
export const API_BASE = (import.meta as any).env?.VITE_API_BASE ?? "https://api.fishtrackpro.ru";

export function buildUrl(path: string, params?: Record<string, any>) {
  const u = new URL(path, API_BASE);
  if (params) {
    Object.entries(params).forEach(([k,v]) => {
      if (v !== undefined && v !== null && v !== '') u.searchParams.set(k, String(v));
    });
  }
  return u.toString();
}
TS

# tabs (Global/Local/Follow)
cat > "$FRONT/src/components/FeedTabs.tsx" <<'TSX'
import React from "react";

type Tab = "global"|"local"|"follow";
const TABS: {key: Tab; label: string}[] = [
  {key:"global", label:"Глобально"},
  {key:"local",  label:"Рядом"},
  {key:"follow", label:"Подписки"},
];

export default function FeedTabs({active, onChange}:{active:Tab; onChange:(t:Tab)=>void}) {
  return (
    <div className="flex gap-2 p-2 rounded-2xl bg-white/60 backdrop-blur border border-white/60 sticky top-0 z-20">
      {TABS.map(t => {
        const is = active===t.key;
        return (
          <button
            key={t.key}
            onClick={()=>onChange(t.key)}
            className={
              "px-3 py-1 rounded-full text-sm " +
              (is ? "bg-white border border-white shadow font-semibold" : "bg-transparent border border-transparent text-gray-600")
            }
            aria-pressed={is}
          >
            {t.label}
          </button>
        );
      })}
    </div>
  );
}
TSX

# card
cat > "$FRONT/src/components/FeedCard.tsx" <<'TSX'
import React from "react";
import type { FeedItem } from "../types/feed";

const fallbackAvatar = "data:image/svg+xml;utf8," + encodeURIComponent(
  `<svg xmlns='http://www.w3.org/2000/svg' width='64' height='64'>
     <rect width='100%' height='100%' rx='8' ry='8' fill='#e5e7eb'/>
     <text x='50%' y='54%' text-anchor='middle' font-size='28' fill='#9ca3af'>👤</text>
   </svg>`
);

export default function FeedCard({ item }: { item: FeedItem }) {
  const name = item.user_name || "Аноним";
  const avatar = item.user_avatar || fallbackAvatar;
  const when   = item.caught_at || item.created_at || null;

  return (
    <article className="rounded-2xl p-3 mb-3 bg-white/70 backdrop-blur border border-white/50 shadow-sm">
      <header className="flex items-center gap-3">
        <img
          src={avatar}
          alt={name}
          className="w-10 h-10 rounded-full object-cover border border-white/70"
          onError={(e)=> (e.currentTarget.src = fallbackAvatar)}
        />
        <div className="min-w-0">
          <div className="text-sm font-semibold text-gray-900 truncate">{name}</div>
          <div className="text-xs text-gray-500">
            {when ? new Date(when).toLocaleString() : ""}
            {item.place_title ? ` • ${item.place_title}` : ""}
          </div>
        </div>
      </header>

      {item.photo_url && (
        <div className="mt-3 overflow-hidden rounded-xl">
          <img src={item.photo_url} alt={item.species ?? "Улов"} className="w-full object-cover max-h-[360px]" />
        </div>
      )}

      <div className="mt-3">
        <div className="text-base font-medium text-gray-900">
          {item.species ?? (item.notes ? item.notes.slice(0,64) + (item.notes.length>64 ? "…" : "") : "Улов")}
        </div>
        <div className="text-sm text-gray-600 flex flex-wrap gap-x-4">
          {item.weight != null && <span>Вес: {item.weight}</span>}
          {item.length != null && <span>Длина: {item.length}</span>}
          {item.style && <span>Стиль: {item.style}</span>}
          {item.lure && <span>Приманка: {item.lure}</span>}
        </div>
      </div>

      <footer className="mt-3 flex items-center gap-4 text-sm text-gray-700">
        <button className="px-3 py-1 rounded-full bg-white/60 border border-white/60">❤ {item.likes_count ?? 0}</button>
        <button className="px-3 py-1 rounded-full bg-white/60 border border-white/60">💬 {item.comments_count ?? 0}</button>
      </footer>
    </article>
  );
}
TSX

# Feed screen with infinite scroll
cat > "$FRONT/src/screens/FeedScreen.tsx" <<'TSX'
import React, { useEffect, useRef, useState } from "react";
import FeedTabs from "../components/FeedTabs";
import FeedCard from "../components/FeedCard";
import type { FeedItem } from "../types/feed";
import { buildUrl } from "../lib/api";

type Tab = "global"|"local"|"follow";

export default function FeedScreen() {
  const [tab, setTab] = useState<Tab>("global");
  const [q, setQ] = useState("");
  const [items, setItems] = useState<FeedItem[]>([]);
  const [offset, setOffset] = useState(0);
  const [hasMore, setHasMore] = useState(true);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const sentinelRef = useRef<HTMLDivElement | null>(null);
  const geoRef = useRef<{lat:number, lng:number} | null>(null);

  // reset on tab/q change
  useEffect(() => {
    setItems([]); setOffset(0); setHasMore(true); setErr(null);
  }, [tab, q]);

  // local tab: get geolocation once
  useEffect(() => {
    if (tab !== "local") return;
    if (geoRef.current) return;
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => { geoRef.current = { lat: pos.coords.latitude, lng: pos.coords.longitude }; },
      () => { geoRef.current = null; },
      { enableHighAccuracy: true, timeout: 5000 }
    );
  }, [tab]);

  // loader
  useEffect(() => {
    if (!hasMore || loading) return;
    const el = sentinelRef.current;
    if (!el) return;
    const io = new IntersectionObserver((entries)=>{
      entries.forEach((e)=>{
        if (e.isIntersecting) fetchMore();
      });
    }, { rootMargin: "300px" });
    io.observe(el);
    return () => io.disconnect();
  }, [hasMore, loading, sentinelRef.current, tab, q]);

  const fetchMore = () => {
    if (!hasMore || loading) return;
    setLoading(true); setErr(null);

    const params: Record<string, any> = { limit: 20, offset, tab, q: q.trim() };
    if (tab === "local" && geoRef.current) {
      params.lat = geoRef.current.lat;
      params.lng = geoRef.current.lng;
      params.radius_km = 50;
    }

    fetch(buildUrl("/api/v1/feed", params), { mode: "cors" })
      .then(async r => { if (!r.ok) throw new Error(`HTTP ${r.status}`); return r.json(); })
      .then(json => {
        const arr: FeedItem[] = Array.isArray(json.items) ? json.items : [];
        setItems(prev => prev.concat(arr));
        if (json.next != null) setOffset(json.next); else setHasMore(false);
      })
      .catch(e => setErr(e.message))
      .finally(()=> setLoading(false));
  };

  return (
    <div className="px-3 pt-3 pb-24">
      <FeedTabs active={tab} onChange={setTab}/>
      <div className="mt-3 sticky top-[56px] z-10">
        <input
          className="w-full rounded-full px-4 py-2 bg-white/60 backdrop-blur border border-white/60"
          placeholder="Поиск по виду, приманке, снастям, заметкам…"
          value={q}
          onChange={(e)=>setQ(e.target.value)}
        />
      </div>

      <div className="mt-3">
        {items.map(it => <FeedCard key={it.id} item={it} />)}
      </div>

      {err && <div className="text-center text-red-500 py-4">Ошибка: {err}</div>}
      {loading && <div className="text-center text-gray-500 py-4">Загрузка…</div>}
      {!loading && !err && items.length===0 && !hasMore && (
        <div className="text-center text-gray-500 py-6">Публикаций пока нет</div>
      )}

      <div ref={sentinelRef} className="h-6" />
    </div>
  );
}
TSX

echo "==> Frontend files written."

echo "----------------------------------------------------"
echo "NEXT STEPS:"
echo "1) Backend: php artisan route:clear && php artisan config:clear"
echo "   Проверка: curl -s \"https://api.fishtrackpro.ru/api/v1/feed?limit=2\" | jq ."
echo "2) Frontend: в .env.production установите VITE_API_BASE=https://api.fishtrackpro.ru"
echo "   Соберите и задеплойте фронт, обновите кэш браузера."
echo "3) CORS: проверьте config/cors.php -> allowed_origins содержит ваш фронт-домен."
echo "4) Готово. Откройте ленту во фронте — бесконечная прокрутка + табы."
echo "----------------------------------------------------"