#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
BACK="$ROOT/backend"
FRONT="$ROOT/frontend"

echo "==> Backend: controllers & routes"

mkdir -p "$BACK/app/Http/Controllers/Api"

# --- CatchWriteController ---
cat > "$BACK/app/Http/Controllers/Api/CatchWriteController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CatchWriteController extends Controller
{
    public function store(Request $r)
    {
        // Валидация под вашу таблицу catch_records
        $data = $r->validate([
            'user_id'   => 'nullable|integer|exists:users,id',
            'lat'       => 'required|numeric',
            'lng'       => 'required|numeric',
            'species'   => 'nullable|string|max:255',
            'length'    => 'nullable|numeric',
            'weight'    => 'nullable|numeric',
            'depth'     => 'nullable|numeric',
            'style'     => 'nullable|string|max:255',
            'lure'      => 'nullable|string|max:255',
            'tackle'    => 'nullable|string|max:255',
            'privacy'   => 'nullable|string|in:all,public,everyone,friends,private',
            'caught_at' => 'nullable|date',
            'water_type'=> 'nullable|string|max:255',
            'water_temp'=> 'nullable|numeric',
            'wind_speed'=> 'nullable|numeric',
            'pressure'  => 'nullable|numeric',
            'companions'=> 'nullable|string|max:255',
            'notes'     => 'nullable|string',
            'photo_url' => 'nullable|string|max:255',
        ]);

        $data['privacy'] = $data['privacy'] ?? 'all';
        $now = now();

        $id = DB::table('catch_records')->insertGetId([
            'user_id'    => $data['user_id']   ?? null,
            'lat'        => $data['lat'],
            'lng'        => $data['lng'],
            'species'    => $data['species']   ?? null,
            'length'     => $data['length']    ?? null,
            'weight'     => $data['weight']    ?? null,
            'depth'      => $data['depth']     ?? null,
            'style'      => $data['style']     ?? null,
            'lure'       => $data['lure']      ?? null,
            'tackle'     => $data['tackle']    ?? null,
            'privacy'    => $data['privacy'],
            'caught_at'  => $data['caught_at'] ?? null,
            'water_type' => $data['water_type']?? null,
            'water_temp' => $data['water_temp']?? null,
            'wind_speed' => $data['wind_speed']?? null,
            'pressure'   => $data['pressure']  ?? null,
            'companions' => $data['companions']?? null,
            'notes'      => $data['notes']     ?? null,
            'photo_url'  => $data['photo_url'] ?? null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $row = DB::table('catch_records')->where('id', $id)->first();
        return response()->json($row, 201);
    }
}
PHP

# --- PointWriteController ---
cat > "$BACK/app/Http/Controllers/Api/PointWriteController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PointWriteController extends Controller
{
    public function store(Request $r)
    {
        // fishing_points: id,user_id,lat,lng,title,description,category,is_public,is_highlighted,status,created_at,updated_at
        $data = $r->validate([
            'user_id'      => 'nullable|integer|exists:users,id',
            'lat'          => 'required|numeric',
            'lng'          => 'required|numeric',
            'title'        => 'required|string|max:255',
            'description'  => 'nullable|string',
            'category'     => 'required|string|in:spot,shop,slip,camp',
            'is_public'    => 'nullable|boolean',
            'is_highlighted'=> 'nullable|boolean',
            'status'       => 'nullable|string|in:approved,pending,rejected',
        ]);

        $now = now();
        $id = DB::table('fishing_points')->insertGetId([
            'user_id'        => $data['user_id'] ?? null,
            'lat'            => $data['lat'],
            'lng'            => $data['lng'],
            'title'          => $data['title'],
            'description'    => $data['description'] ?? null,
            'category'       => $data['category'],
            'is_public'      => array_key_exists('is_public',$data) ? (int)$data['is_public'] : 1,
            'is_highlighted' => array_key_exists('is_highlighted',$data) ? (int)$data['is_highlighted'] : 0,
            'status'         => $data['status'] ?? 'approved',
            'created_at'     => $now,
            'updated_at'     => $now,
        ]);

        $row = DB::table('fishing_points')->where('id',$id)->first();
        return response()->json($row, 201);
    }

    public function categories()
    {
        return response()->json([
            'items' => ['spot','shop','slip','camp']
        ]);
    }
}
PHP

# --- routes ---
ROUTES="$BACK/routes/api.php"
if ! grep -q "CatchWriteController" "$ROUTES"; then
  cat >> "$ROUTES" <<'PHP'

// --- WRITE ENDPOINTS (create catch/place) ---
use App\Http\Controllers\Api\CatchWriteController;
use App\Http\Controllers\Api\PointWriteController;

Route::prefix('v1')->group(function () {
    Route::post('/catches', [CatchWriteController::class,'store']); // POST /api/v1/catches
    Route::post('/points',  [PointWriteController::class,'store']); // POST /api/v1/points
    Route::get('/points/categories', [PointWriteController::class,'categories']); // справочник
});
PHP
fi

echo "==> Frontend: forms & helpers"

mkdir -p "$FRONT/src/components" "$FRONT/src/screens" "$FRONT/src/lib"

# Toast helper
cat > "$FRONT/src/lib/toast.ts" <<'TS'
export function toast(msg: string) {
  const el = document.createElement('div');
  el.textContent = msg;
  el.className = 'fixed left-1/2 -translate-x-1/2 bottom-24 px-4 py-2 rounded-full bg-black/70 text-white text-sm z-[1000]';
  document.body.appendChild(el);
  setTimeout(()=> el.remove(), 2200);
}
TS

# Modal component
cat > "$FRONT/src/components/Modal.tsx" <<'TSX'
import React from "react";

export default function Modal({open, onClose, children, title}:{open:boolean; onClose:()=>void; title?:string; children:React.ReactNode}) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50">
      <div className="absolute inset-0 bg-black/40" onClick={onClose}/>
      <div className="absolute left-1/2 top-10 -translate-x-1/2 w-[min(640px,95vw)] rounded-2xl bg-white/80 backdrop-blur border border-white/60 shadow-xl p-4">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold">{title ?? "Форма"}</h3>
          <button className="px-2 py-1 text-gray-500 hover:text-black" onClick={onClose}>✕</button>
        </div>
        <div className="mt-2">{children}</div>
      </div>
    </div>
  );
}
TSX

# API base (если ещё нет)
if [ ! -f "$FRONT/src/lib/api.ts" ]; then
cat > "$FRONT/src/lib/api.ts" <<'TS'
export const API_BASE = (import.meta as any).env?.VITE_API_BASE ?? "https://api.fishtrackpro.ru";
export function buildUrl(path: string) { return new URL(path, API_BASE).toString(); }
TS
fi

# AddCatchScreen
cat > "$FRONT/src/screens/AddCatchScreen.tsx" <<'TSX'
import React, { useState } from "react";
import { buildUrl } from "../lib/api";
import { toast } from "../lib/toast";

export default function AddCatchScreen({onDone}:{onDone:()=>void}) {
  const [form, setForm] = useState({
    species: "", length: "", weight: "", style: "", lure: "", tackle: "",
    notes: "", photo_url: "", lat: "", lng: "", caught_at: "", privacy: "all"
  });
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string|null>(null);

  const set = (k: string, v: string) => setForm(p=>({...p, [k]: v}));

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true); setErr(null);
    try {
      const payload: any = {
        lat: Number(form.lat), lng: Number(form.lng),
        species: form.species || null,
        length: form.length ? Number(form.length) : null,
        weight: form.weight ? Number(form.weight) : null,
        style: form.style || null, lure: form.lure || null, tackle: form.tackle || null,
        notes: form.notes || null, photo_url: form.photo_url || null,
        caught_at: form.caught_at || null,
        privacy: form.privacy || "all",
      };
      const res = await fetch(buildUrl("/api/v1/catches"), {
        method: "POST",
        headers: { "Content-Type":"application/json", "Accept":"application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      toast("Улов добавлен");
      onDone();
    } catch (e:any) {
      setErr(e.message ?? String(e));
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={submit} className="space-y-3">
      <div className="grid grid-cols-2 gap-3">
        <input className="input" placeholder="Широта (lat)" value={form.lat} onChange={e=>set("lat", e.target.value)} required />
        <input className="input" placeholder="Долгота (lng)" value={form.lng} onChange={e=>set("lng", e.target.value)} required />
      </div>
      <div className="grid grid-cols-2 gap-3">
        <input className="input" placeholder="Вид рыбы" value={form.species} onChange={e=>set("species", e.target.value)} />
        <input className="input" placeholder="Вес (кг)" value={form.weight} onChange={e=>set("weight", e.target.value)} />
      </div>
      <div className="grid grid-cols-2 gap-3">
        <input className="input" placeholder="Длина (см)" value={form.length} onChange={e=>set("length", e.target.value)} />
        <input className="input" placeholder="Стиль" value={form.style} onChange={e=>set("style", e.target.value)} />
      </div>
      <div className="grid grid-cols-2 gap-3">
        <input className="input" placeholder="Приманка" value={form.lure} onChange={e=>set("lure", e.target.value)} />
        <input className="input" placeholder="Снасти" value={form.tackle} onChange={e=>set("tackle", e.target.value)} />
      </div>
      <input className="input" placeholder="Фото (URL)" value={form.photo_url} onChange={e=>set("photo_url", e.target.value)} />
      <input className="input" type="datetime-local" placeholder="Дата/время" value={form.caught_at} onChange={e=>set("caught_at", e.target.value)} />
      <select className="input" value={form.privacy} onChange={e=>set("privacy", e.target.value)}>
        <option value="all">Публично</option>
        <option value="friends">Друзья</option>
        <option value="private">Приватно</option>
      </select>
      <textarea className="input" placeholder="Заметки" value={form.notes} onChange={e=>set("notes", e.target.value)} />
      {err && <div className="text-red-500 text-sm">{err}</div>}
      <div className="flex gap-2 justify-end">
        <button type="button" className="btn-secondary" onClick={onDone}>Отмена</button>
        <button type="submit" className="btn-primary" disabled={loading}>{loading?"Сохранение…":"Сохранить"}</button>
      </div>
    </form>
  );
}
TSX

# AddPlaceScreen
cat > "$FRONT/src/screens/AddPlaceScreen.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { buildUrl } from "../lib/api";
import { toast } from "../lib/toast";

export default function AddPlaceScreen({onDone}:{onDone:()=>void}) {
  const [cats, setCats] = useState<string[]>(["spot","shop","slip","camp"]);
  const [form, setForm] = useState({
    title:"", description:"", category:"spot", lat:"", lng:"",
    is_public:true, is_highlighted:false
  });
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string|null>(null);

  useEffect(() => {
    fetch(buildUrl("/api/v1/points/categories"))
      .then(r => r.ok ? r.json(): Promise.reject(r.status))
      .then(j => Array.isArray(j.items) ? setCats(j.items) : null)
      .catch(()=>{ /* необязательно */ });
  }, []);

  const set = (k: string, v: any) => setForm(p=>({...p, [k]: v}));

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true); setErr(null);
    try {
      const payload: any = {
        title: form.title,
        description: form.description || null,
        category: form.category,
        lat: Number(form.lat), lng: Number(form.lng),
        is_public: !!form.is_public,
        is_highlighted: !!form.is_highlighted,
        status: 'approved',
      };
      const res = await fetch(buildUrl("/api/v1/points"), {
        method: "POST",
        headers: { "Content-Type":"application/json", "Accept":"application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      toast("Место добавлено");
      onDone();
    } catch (e:any) {
      setErr(e.message ?? String(e));
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={submit} className="space-y-3">
      <input className="input" placeholder="Название" value={form.title} onChange={e=>set("title", e.target.value)} required />
      <textarea className="input" placeholder="Описание" value={form.description} onChange={e=>set("description", e.target.value)} />
      <div className="grid grid-cols-2 gap-3">
        <input className="input" placeholder="Широта (lat)" value={form.lat} onChange={e=>set("lat", e.target.value)} required />
        <input className="input" placeholder="Долгота (lng)" value={form.lng} onChange={e=>set("lng", e.target.value)} required />
      </div>
      <select className="input" value={form.category} onChange={e=>set("category", e.target.value)}>
        {cats.map(c => <option key={c} value={c}>{c}</option>)}
      </select>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" checked={form.is_public} onChange={e=>set("is_public", e.target.checked)} />
        Публично
      </label>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" checked={form.is_highlighted} onChange={e=>set("is_highlighted", e.target.checked)} />
        Выделить на карте
      </label>
      {err && <div className="text-red-500 text-sm">{err}</div>}
      <div className="flex gap-2 justify-end">
        <button type="button" className="btn-secondary" onClick={onDone}>Отмена</button>
        <button type="submit" className="btn-primary" disabled={loading}>{loading?"Сохранение…":"Сохранить"}</button>
      </div>
    </form>
  );
}
TSX

# Tailwind-ish utility classes used in forms (scoped via global.css)
mkdir -p "$FRONT/src/styles"
if ! grep -q ".input" "$FRONT/src/styles/forms.css" 2>/dev/null; then
cat > "$FRONT/src/styles/forms.css" <<'CSS'
.input { @apply w-full rounded-xl px-3 py-2 bg-white/70 backdrop-blur border border-white/60 outline-none; }
.btn-primary { @apply rounded-full px-4 py-2 bg-black text-white; }
.btn-secondary { @apply rounded-full px-4 py-2 bg-white/70 border border-white/60; }
CSS
fi

# Ensure import of forms.css in main css (if you use Tailwind index.css, append safe)
CSS_ENTRY="$FRONT/src/index.css"
if [ -f "$CSS_ENTRY" ] && ! grep -q "styles/forms.css" "$CSS_ENTRY"; then
  echo '@import "./styles/forms.css";' >> "$CSS_ENTRY"
fi

# Patch App.tsx safely (backup then write a minimal version that wires FAB -> chooser -> modal forms)
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

  const onFab=()=>{
    // Показываем селектор: Добавить улов / Добавить место
    setForm("chooser");
  };

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
          <button className="btn-primary" onClick={()=>setForm("catch")}>🎣 Улов</button>
          <button className="btn-secondary" onClick={()=>setForm("place")}>📍 Место</button>
        </div>
      </Modal>

      {/* Форма улова */}
      <Modal open={form==="catch"} onClose={closeAll} title="Добавить улов">
        <AddCatchScreen onDone={closeAll}/>
      </Modal>

      {/* Форма места */}
      <Modal open={form==="place"} onClose={closeAll} title="Добавить место">
        <AddPlaceScreen onDone={closeAll}/>
      </Modal>
    </div>
  );
}
TSX

echo "==> Done."

echo
echo "Next steps:"
echo "  1) Backend: php artisan route:clear && php artisan config:clear"
echo "     Проверка POST (пример):"
echo "     curl -i -H 'Content-Type: application/json' -d '{\"lat\":55.75,\"lng\":37.62,\"species\":\"Окунь\"}' https://api.fishtrackpro.ru/api/v1/catches"
echo "     curl -i -H 'Content-Type: application/json' -d '{\"title\":\"Пирс\",\"category\":\"spot\",\"lat\":55.75,\"lng\":37.62}' https://api.fishtrackpro.ru/api/v1/points"
echo "  2) Frontend: убедитесь, что VITE_API_BASE=https://api.fishtrackpro.ru и соберите фронт."
echo "  3) Обновите страницу. FAB -> выбор -> форма."