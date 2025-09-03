#!/usr/bin/env bash
# fishtrackpro_apply_patch.sh
# ------------------------------------------------------------------------------
# Единый установочный скрипт для FishTrackPro:
# - Бэкенд (Laravel): фиксы фида, CORS/401 JSON, эндпоинты карты, конфиги UI и map_icons
# - Фронтенд (Vite/React): экран ленты, форма добавления улова, карта OSM с разнотипными пинами
# - Nginx: конфиги для api. и www. доменов (без редиректов с API на WEB)
#
# Запуск:
#   chmod +x fishtrackpro_apply_patch.sh
#   ./fishtrackpro_apply_patch.sh all               # применить всё
#   ./fishtrackpro_apply_patch.sh backend           # только бэкенд
#   ./fishtrackpro_apply_patch.sh frontend          # только фронтенд
#   ./fishtrackpro_apply_patch.sh nginx             # только nginx-конфиги
#
# Путь запуска:
#   - backend: из корня Laravel-проекта (где есть app/, config/, routes/)
#   - frontend: из корня фронта (где есть src/, .env и т.п.) — для простоты скрипт создаёт src/ при отсутствии
#   - nginx: создаст файлы в ./nginx/ (дальше включите их в конфигурацию вашего сервера)
# ------------------------------------------------------------------------------

set -euo pipefail

# ---------- Утилиты ----------
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
red() { printf "\033[31m%s\033[0m\n" "$*"; }
mkd() { install -d "$1"; }

# ---------- Бэкенд ----------
backend_middleware() {
  mkd app/Http/Middleware
  cat > app/Http/Middleware/ForceJsonResponse.php <<'PHP'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class ForceJsonResponse
{
    public function handle(Request $request, Closure $next)
    {
        $request->headers->set('Accept', 'application/json');
        return $next($request);
    }
}
PHP
}

backend_resource() {
  mkd app/Http/Resources
  cat > app/Http/Resources/CatchResource.php <<'PHP'
<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class CatchResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $avatarUrl = '';
        if (!empty($this->user_avatar_path)) {
            $avatarUrl = preg_match('#^https?://#', $this->user_avatar_path)
                ? $this->user_avatar_path
                : Storage::disk('public')->url($this->user_avatar_path);
        }

        $mediaUrl = '';
        if (!empty($this->photo_url)) {
            $mediaUrl = preg_match('#^https?://#', $this->photo_url)
                ? $this->photo_url
                : Storage::disk('public')->url($this->photo_url);
        }

        return [
            'id' => (int)$this->id,
            'user_id' => (int)$this->user_id,
            'user_name' => (string)($this->user_name ?? ''),
            'user_avatar' => $avatarUrl,
            'lat' => (float)$this->lat,
            'lng' => (float)$this->lng,
            'species' => (string)($this->species ?? ''),
            'length' => is_null($this->length) ? null : (float)$this->length,
            'weight' => is_null($this->weight) ? null : (float)$this->weight,
            'depth' => is_null($this->depth) ? null : (float)$this->depth,
            'method' => (string)($this->style ?? ''),
            'bait' => (string)($this->lure ?? ''),
            'gear' => (string)($this->tackle ?? ''),
            'water_type' => (string)($this->water_type ?? ''),
            'water_temp' => is_null($this->water_temp) ? null : (float)$this->water_temp,
            'wind_speed' => is_null($this->wind_speed) ? null : (float)$this->wind_speed,
            'pressure' => is_null($this->pressure) ? null : (float)$this->pressure,
            'companions' => (string)($this->companions ?? ''),
            'caption' => (string)($this->notes ?? ''),
            'media_url' => $mediaUrl,
            'privacy' => (string)($this->privacy ?? 'all'),
            'caught_at' => $this->caught_at ? $this->caught_at : null,
            'created_at' => $this->created_at,
            'likes_count' => (int)($this->likes_count ?? 0),
            'comments_count' => (int)($this->comments_count ?? 0),
            'liked_by_me' => (bool)($this->liked_by_me ?? false),
        ];
    }
}
PHP
}

backend_controllers() {
  mkd app/Http/Controllers/Api/V1
  cat > app/Http/Controllers/Api/V1/FeedController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\CatchResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FeedController extends Controller
{
    public function index(Request $request)
    {
        $limit = (int)($request->query('limit', 20));
        $offset = (int)($request->query('offset', 0));
        $viewerId = $request->user()?->id;

        $sql = "
            SELECT 
                cr.id,
                cr.user_id,
                u.name AS user_name,
                u.avatar_path AS user_avatar_path,
                cr.lat, cr.lng, cr.species, cr.length, cr.weight, cr.depth,
                cr.style, cr.lure, cr.tackle,
                cr.water_type, cr.water_temp, cr.wind_speed, cr.pressure,
                cr.companions,
                cr.notes, cr.photo_url, cr.privacy, cr.caught_at,
                cr.created_at,
                (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count,
                (SELECT COUNT(*) FROM catch_comments cc 
                    WHERE cc.catch_id=cr.id 
                      AND (cc.is_approved=1 OR cc.is_approved IS NULL)
                ) AS comments_count,
                " . ($viewerId ? "EXISTS(SELECT 1 FROM catch_likes cl2 WHERE cl2.catch_id=cr.id AND cl2.user_id=?)" : "0") . " AS liked_by_me
            FROM catch_records cr
            LEFT JOIN users u ON u.id = cr.user_id
            WHERE 
                (
                    cr.privacy = 'all'
                    OR (
                        cr.privacy = 'friends' 
                        AND " . ($viewerId ? "EXISTS(SELECT 1 FROM friendships f
                              WHERE ((f.user_id = cr.user_id AND f.friend_id = ?) OR (f.user_id = ? AND f.friend_id = cr.user_id))
                                AND f.status = 'accepted')" : "0") . "
                    )
                )
            ORDER BY cr.created_at DESC
            LIMIT ? OFFSET ?
        ";

        $bindings = [];
        if ($viewerId) {
            $bindings[] = $viewerId;
            $bindings[] = $viewerId;
            $bindings[] = $viewerId;
        }
        $bindings[] = $limit;
        $bindings[] = $offset;

        $rows = DB::select($sql, $bindings);

        return CatchResource::collection(collect($rows));
    }
}
PHP

  cat > app/Http/Controllers/Api/V1/CatchController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCatchRequest;
use App\Http\Resources\CatchResource;
use Illuminate\Support\Facades\DB;

class CatchController extends Controller
{
    public function store(StoreCatchRequest $request)
    {
        $userId = $request->user()->id;

        $photoPath = $request->input('photo_url');
        if ($request->hasFile('photo')) {
            $photoPath = $request->file('photo')->store('catches', 'public');
        }

        $id = DB::table('catch_records')->insertGetId([
            'user_id' => $userId,
            'lat' => $request->float('lat'),
            'lng' => $request->float('lng'),
            'species' => $request->input('species'),
            'length' => $request->input('length'),
            'weight' => $request->input('weight'),
            'depth' => $request->input('depth'),
            'style' => $request->input('style'),
            'lure' => $request->input('lure'),
            'tackle' => $request->input('tackle'),
            'privacy' => $request->input('privacy', 'all'),
            'caught_at' => $request->input('caught_at'),
            'water_type' => $request->input('water_type'),
            'water_temp' => $request->input('water_temp'),
            'wind_speed' => $request->input('wind_speed'),
            'pressure' => $request->input('pressure'),
            'companions' => $request->input('companions'),
            'notes' => $request->input('notes'),
            'photo_url' => $photoPath,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $row = DB::table('catch_records as cr')
            ->leftJoin('users as u','u.id','=','cr.user_id')
            ->where('cr.id',$id)
            ->selectRaw("
                cr.*, 
                u.name as user_name, 
                u.avatar_path as user_avatar_path,
                (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count,
                (SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id=cr.id AND (cc.is_approved=1 OR cc.is_approved IS NULL)) AS comments_count
            ")->first();

        return (new CatchResource($row))->response()->setStatusCode(201);
    }
}
PHP

  cat > app/Http/Controllers/Api/V1/MapController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MapController extends Controller
{
    public function icons(Request $request)
    {
        return response()->json(config('map_icons'));
    }

    public function points(Request $request)
    {
        $limit = (int)($request->query('limit', 1000));
        $offset = (int)($request->query('offset', 0));

        $points = DB::table('fishing_points')
            ->select('id','lat','lng','title','description','category','is_highlighted','status')
            ->where('is_public', 1)
            ->where('status', 'approved')
            ->orderByDesc('id')
            ->limit($limit)->offset($offset)
            ->get()
            ->map(function($p){
                return [
                    'id' => (int)$p->id,
                    'type' => $p->category ?? 'spot',
                    'lat' => (float)$p->lat,
                    'lng' => (float)$p->lng,
                    'title' => $p->title ?? '',
                    'descr' => $p->description ?? '',
                    'highlight' => (bool)($p->is_highlighted ?? false),
                    'source' => 'fishing_points',
                ];
            })->toArray();

        $stores = DB::table('stores')
            ->select('id','lat','lng','name','address','category')
            ->whereNotNull('lat')->whereNotNull('lng')
            ->orderByDesc('id')
            ->limit($limit)->offset($offset)
            ->get()
            ->map(function($s){
                return [
                    'id' => (int)$s->id,
                    'type' => $s->category ? strtolower($s->category) : 'store',
                    'lat' => (float)$s->lat,
                    'lng' => (float)$s->lng,
                    'title' => $s->name ?? '',
                    'descr' => $s->address ?? '',
                    'highlight' => false,
                    'source' => 'stores',
                ];
            })->toArray();

        $events = DB::table('events')
            ->select('id','title','location_lat','location_lng','region','starts_at','ends_at')
            ->whereNotNull('location_lat')->whereNotNull('location_lng')
            ->orderByDesc('starts_at')
            ->limit($limit)->offset($offset)
            ->get()
            ->map(function($e){
                return [
                    'id' => (int)$e->id,
                    'type' => 'event',
                    'lat' => (float)$e->location_lat,
                    'lng' => (float)$e->location_lng,
                    'title' => $e->title ?? '',
                    'descr' => trim(($e->region ?? '').' '.($e->starts_at ?? '')),
                    'highlight' => false,
                    'source' => 'events',
                ];
            })->toArray();

        return response()->json([
            'items' => array_values(array_merge($points, $stores, $events)),
        ]);
    }
}
PHP
}

backend_request_rules() {
  mkd app/Http/Requests
  cat > app/Http/Requests/StoreCatchRequest.php <<'PHP'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCatchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool)$this->user();
    }

    public function rules(): array
    {
        return [
            'lat' => ['required','numeric','between:-90,90'],
            'lng' => ['required','numeric','between:-180,180'],
            'species' => ['nullable','string','max:255'],
            'length' => ['nullable','numeric'],
            'weight' => ['nullable','numeric'],
            'depth' => ['nullable','numeric'],
            'style' => ['nullable','string','max:255'],
            'lure' => ['nullable','string','max:255'],
            'tackle' => ['nullable','string','max:255'],
            'privacy' => ['required','in:all,friends'],
            'caught_at' => ['nullable','date'],
            'water_type' => ['nullable','string','max:255'],
            'water_temp' => ['nullable','numeric'],
            'wind_speed' => ['nullable','numeric'],
            'pressure' => ['nullable','numeric'],
            'companions' => ['nullable','string','max:255'],
            'notes' => ['nullable','string'],
            'photo' => ['nullable','file','image','max:8192'],
            'photo_url' => ['nullable','string','max:255'],
        ];
    }
}
PHP
}

backend_routes() {
  mkd routes
  cat > routes/api.php <<'PHP'
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\FeedController;
use App\Http\Controllers\Api\V1\CatchController;
use App\Http\Controllers\Api\V1\MapController;
use App\Http\Middleware\ForceJsonResponse;

Route::middleware([ForceJsonResponse::class, 'throttle:api', \Fruitcake\Cors\HandleCors::class])->prefix('v1')->group(function () {

    Route::get('/feed', [FeedController::class, 'index']);

    Route::get('/map/icons', [MapController::class, 'icons']);
    Route::get('/map/points', [MapController::class, 'points']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/catches', [CatchController::class, 'store']);
    });
});
PHP
}

backend_handler_401() {
  mkd app/Exceptions
  cat > app/Exceptions/Handler.php <<'PHP'
<?php

namespace App\Exceptions;

use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Throwable;
use Illuminate\Auth\AuthenticationException;

class Handler extends ExceptionHandler
{
    protected $levels = [];
    protected $dontReport = [];
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    public function register(): void
    {
        //
    }

    protected function unauthenticated($request, AuthenticationException $exception)
    {
        if ($request->expectsJson() || $request->is('api/*')) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }
        return redirect()->guest(route('login'));
    }
}
PHP
}

backend_configs() {
  mkd config
  cat > config/cors.php <<'PHP'
<?php

return [
    'paths' => [
        'api/*',
        'sanctum/csrf-cookie',
    ],
    'allowed_methods' => ['*'],
    'allowed_origins' => [
        'https://www.fishtrackpro.ru',
        'https://fishtrackpro.ru',
        'http://localhost:3000',
        'http://localhost:5173',
    ],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true,
];
PHP

  cat > config/ui.php <<'PHP'
<?php

return [
    'logo_url' => env('UI_LOGO_URL', '/images/logo.svg'),
    'default_avatar' => env('UI_DEFAULT_AVATAR', '/images/default-avatar.png'),
    'bg_pattern' => env('UI_BG_PATTERN', '/images/pattern.png'),
];
PHP

  cat > config/map_icons.php <<'PHP'
<?php

/**
 * Карта иконок для типов точек на карте.
 * Для каждого типа можно указать строку (URL) или расширенный объект:
 * ['url' => '...', 'size' => [w,h], 'anchor' => [x,y], 'popup' => [x,y]]
 */
return [
    'types' => [
        'spot' => [
            'url' => env('ICON_SPOT', '/icons/spot.png'),
            'size' => [32, 32],
            'anchor' => [16, 32],
            'popup' => [0, -28],
        ],
        'store' => [
            'url' => env('ICON_STORE', '/icons/store.png'),
            'size' => [28, 28],
            'anchor' => [14, 28],
            'popup' => [0, -24],
        ],
        'base' => env('ICON_BASE', '/icons/base.png'),
        'slip' => env('ICON_SLIP', '/icons/slip.png'),
        'farm' => env('ICON_FARM', '/icons/farm.png'),
        'event' => [
            'url' => env('ICON_EVENT', '/icons/event.png'),
            'size' => [30, 30],
            'anchor' => [15, 30],
            'popup' => [0, -26],
        ],
        'club' => env('ICON_CLUB', '/icons/club.png'),
        'highlight' => [
            'url' => env('ICON_HIGHLIGHT', '/icons/highlight.png'),
            'size' => [36, 36],
            'anchor' => [18, 36],
            'popup' => [0, -32],
        ],
    ],
    'default' => [
        'url' => env('ICON_DEFAULT', '/icons/default.png'),
        'size' => [26, 26],
        'anchor' => [13, 26],
        'popup' => [0, -22],
    ],
];
PHP

  if ! grep -q "UI_LOGO_URL" .env.example 2>/dev/null; then
    cat >> .env.example <<'ENV'

# --- UI assets ---
UI_LOGO_URL=/images/logo.svg
UI_DEFAULT_AVATAR=/images/default-avatar.png
UI_BG_PATTERN=/images/pattern.png

# --- Map icons ---
ICON_DEFAULT=/icons/default.png
ICON_SPOT=/icons/spot.png
ICON_STORE=/icons/store.png
ICON_BASE=/icons/base.png
ICON_SLIP=/icons/slip.png
ICON_FARM=/icons/farm.png
ICON_EVENT=/icons/event.png
ICON_CLUB=/icons/club.png
ICON_HIGHLIGHT=/icons/highlight.png

# --- Frontend/CORS ---
FRONTEND_URL=https://www.fishtrackpro.ru
APP_URL_API=https://api.fishtrackpro.ru
ENV
  fi
}

backend_all() {
  backend_middleware
  backend_resource
  backend_controllers
  backend_request_rules
  backend_routes
  backend_handler_401
  backend_configs
  green "✅ Бэкенд файлы обновлены."
  yellow "ℹ Не забудьте: composer require fruitcake/laravel-cors && php artisan config:clear route:clear cache:clear && php artisan storage:link"
}

# ---------- Фронтенд ----------
frontend_api() {
  mkd src/api
  cat > src/api/api.ts <<'TS'
export interface CatchItem {
  id: number;
  user_id: number;
  user_name: string;
  user_avatar: string;
  lat: number;
  lng: number;
  species?: string;
  length?: number;
  weight?: number;
  depth?: number;
  method?: string;
  bait?: string;
  gear?: string;
  water_type?: string;
  water_temp?: number;
  wind_speed?: number;
  pressure?: number;
  companions?: string;
  caption?: string;
  media_url?: string;
  privacy: 'all'|'friends';
  caught_at?: string | null;
  created_at: string;
  likes_count: number;
  comments_count: number;
  liked_by_me: boolean;
}

export interface MapIcons {
  types: Record<string, string | { url: string; size?: [number,number]; anchor?: [number,number]; popup?: [number,number]; }>;
  default: string | { url: string; size?: [number,number]; anchor?: [number,number]; popup?: [number,number]; };
}

export interface MapPoint {
  id: number;
  type: string;
  lat: number;
  lng: number;
  title: string;
  descr?: string;
  highlight?: boolean;
  source: 'fishing_points'|'stores'|'events';
}

const API_BASE = import.meta.env.VITE_API_BASE ?? 'https://api.fishtrackpro.ru/api/v1';

async function http<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    credentials: 'include',
    headers: {
      ...(opts.headers ?? {}),
    },
    ...opts
  });
  if (!res.ok) {
    const text = await res.text().catch(()=>'');
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json();
}

export async function fetchFeed(limit=10, offset=0) {
  return http<CatchItem[]>(`/feed?limit=${limit}&offset=${offset}`);
}

export async function createCatch(form: FormData) {
  const res = await fetch(`${API_BASE}/catches`, {
    method: 'POST',
    body: form,
    credentials: 'include'
  });
  if (!res.ok) {
    const text = await res.text().catch(()=>'');
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json() as Promise<CatchItem>;
}

export async function fetchMapIcons() {
  return http<MapIcons>('/map/icons');
}

export async function fetchMapPoints(limit=2000, offset=0) {
  return http<{items: MapPoint[]}>(`/map/points?limit=${limit}&offset=${offset}`);
}
TS
}

frontend_screens() {
  mkd src/screens
  cat > src/screens/FeedScreen.tsx <<'TSX'
import { useEffect, useState } from 'react';
import { fetchFeed, CatchItem } from '../api/api';

export default function FeedScreen() {
  const [items, setItems] = useState<CatchItem[]>([]);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    (async () => {
      try {
        const data = await fetchFeed(10, 0);
        setItems(data);
      } catch (e:any) {
        console.error('feed error', e);
        setError('Не удалось загрузить ленту');
      }
    })();
  }, []);

  if (error) return <div className="p-4 text-red-600">{error}</div>;

  return (
    <div className="p-4 space-y-4">
      {items.map(it => (
        <article key={it.id} className="border rounded-xl p-4 shadow-sm">
          <header className="flex items-center gap-3">
            <img src={it.user_avatar || '/images/default-avatar.png'} className="w-10 h-10 rounded-full object-cover" />
            <div>
              <div className="font-semibold">{it.user_name}</div>
              <div className="text-xs text-gray-500">{new Date(it.created_at).toLocaleString()}</div>
            </div>
          </header>
          {it.media_url && (
            <div className="mt-3">
              <img src={it.media_url} className="w-full rounded-lg object-cover" />
            </div>
          )}
          <div className="mt-3 text-sm">
            {it.caption}
          </div>
          <footer className="mt-3 text-xs text-gray-500 flex gap-4">
            <span>👍 {it.likes_count}</span>
            <span>💬 {it.comments_count}</span>
            <span>🐟 {it.species || '—'}</span>
            <span>🔒 {it.privacy}</span>
          </footer>
        </article>
      ))}
    </div>
  );
}
TSX

  cat > src/screens/AddCatchForm.tsx <<'TSX'
import { useState } from 'react';
import { createCatch } from '../api/api';

export default function AddCatchForm() {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>('');
  const [ok, setOk] = useState<string>('');

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setBusy(true); setError(''); setOk('');
    const form = new FormData(e.currentTarget);
    try {
      await createCatch(form);
      setOk('Улов добавлен!');
      e.currentTarget.reset();
    } catch (e:any) {
      console.error(e);
      setError('Ошибка при добавлении улова');
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="p-4 space-y-3 max-w-2xl">
      {error && <div className="text-red-600">{error}</div>}
      {ok && <div className="text-green-700">{ok}</div>}

      <div className="grid grid-cols-2 gap-3">
        <label className="flex flex-col">
          <span>Широта (lat)*</span>
          <input name="lat" type="number" step="any" required className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Долгота (lng)*</span>
          <input name="lng" type="number" step="any" required className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Вид рыбы (species)</span>
          <input name="species" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Длина (length, см)</span>
          <input name="length" type="number" step="any" className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Вес (weight, кг)</span>
          <input name="weight" type="number" step="any" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Глубина (depth, м)</span>
          <input name="depth" type="number" step="any" className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Метод (style)</span>
          <input name="style" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Приманка (lure)</span>
          <input name="lure" className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Снасть (tackle)</span>
          <input name="tackle" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Приватность*</span>
          <select name="privacy" required className="border rounded p-2">
            <option value="all">all</option>
            <option value="friends">friends</option>
          </select>
        </label>

        <label className="flex flex-col">
          <span>Тип воды (water_type)</span>
          <input name="water_type" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Температура воды (°C)</span>
          <input name="water_temp" type="number" step="any" className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Скорость ветра (м/с)</span>
          <input name="wind_speed" type="number" step="any" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Давление (hPa)</span>
          <input name="pressure" type="number" step="any" className="border rounded p-2" />
        </label>

        <label className="flex flex-col">
          <span>Компаньоны</span>
          <input name="companions" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Дата/время поимки</span>
          <input name="caught_at" type="datetime-local" className="border rounded p-2" />
        </label>
      </div>

      <label className="flex flex-col">
        <span>Заметки</span>
        <textarea name="notes" className="border rounded p-2" rows={3} />
      </label>

      <div className="grid grid-cols-2 gap-3">
        <label className="flex flex-col">
          <span>Фото (файл)</span>
          <input name="photo" type="file" accept="image/*" className="border rounded p-2" />
        </label>
        <label className="flex flex-col">
          <span>Или ссылка на фото (photo_url)</span>
          <input name="photo_url" className="border rounded p-2" />
        </label>
      </div>

      <button className="px-4 py-2 rounded bg-blue-600 text-white">
        Добавить улов
      </button>
    </form>
  );
}
TSX
}

frontend_map() {
  mkd src/components
  cat > src/components/MapScreen.tsx <<'TSX'
import { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { fetchMapIcons, fetchMapPoints, MapPoint } from '../api/api';

const TILE_URL = import.meta.env.VITE_OSM_TILES ?? 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
const TILE_ATTR = import.meta.env.VITE_OSM_ATTR ?? '&copy; OpenStreetMap contributors';

type IconCfg = string | { url: string; size?: [number, number]; anchor?: [number, number]; popup?: [number, number]; };
type IconConfigPayload = { types: Record<string, IconCfg>; default: IconCfg };

function toLeafletIcon(cfg: IconCfg): L.Icon {
  const base = typeof cfg === 'string' ? { url: cfg } : cfg;
  const size = (base as any).size ?? [32, 32];
  const anchor = (base as any).anchor ?? [size[0] / 2, size[1]];
  const popup = (base as any).popup ?? [0, - Math.max(22, Math.round(size[1] * 0.8))];
  return L.icon({
    iconUrl: (base as any).url,
    iconSize: size as L.PointTuple,
    iconAnchor: anchor as L.PointTuple,
    popupAnchor: popup as L.PointTuple,
  });
}

export default function MapScreen() {
  const mapEl = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    if (!mapEl.current) return;

    const map = L.map(mapEl.current).setView([55.751244, 37.618423], 5);
    mapRef.current = map;

    L.tileLayer(TILE_URL, {
      attribution: TILE_ATTR,
      maxZoom: 19,
    }).addTo(map);

    (async () => {
      try {
        const iconsCfg = (await fetchMapIcons()) as unknown as IconConfigPayload;
        const res = await fetchMapPoints(2000, 0);

        const cache: Record<string, L.Icon> = {};
        const makeIcon = (type: string) => {
          if (cache[type]) return cache[type];
          const cfg: IconCfg = iconsCfg.types[type] ?? iconsCfg.default;
          const icon = toLeafletIcon(cfg);
          cache[type] = icon;
          return icon;
        };

        res.items.forEach((p: MapPoint) => {
          const t = p.highlight ? 'highlight' : p.type;
          const marker = L.marker([p.lat, p.lng], { icon: makeIcon(t) });
          const html = `
            <div>
              <strong>${p.title ?? ''}</strong><br/>
              <small>${p.descr ?? ''}</small><br/>
              <span>Тип: ${p.type}</span>
            </div>
          `;
          marker.bindPopup(html);
          marker.addTo(map);
        });
      } catch (e:any) {
        console.error(e);
        setError('Не удалось загрузить карту/точки');
      }
    })();

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  return (
    <div className="w-full h-[80vh]">
      {error && <div className="p-2 text-red-600">{error}</div>}
      <div ref={mapEl} className="w-full h-full rounded-xl overflow-hidden shadow" />
    </div>
  );
}
TSX
}

frontend_env() {
  cat > .env.example <<'ENV'
VITE_API_BASE=https://api.fishtrackpro.ru/api/v1
VITE_OSM_TILES=https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
VITE_OSM_ATTR=&copy; OpenStreetMap contributors
ENV
}

frontend_all() {
  frontend_api
  frontend_screens
  frontend_map
  frontend_env
  green "✅ Фронтенд файлы обновлены."
  yellow "ℹ Установите зависимости: npm i leaflet"
}

# ---------- Nginx ----------
nginx_make() {
  mkd nginx
  cat > nginx/api.fishtrackpro.ru.conf <<'NGINX'
server {
    listen 80;
    server_name api.fishtrackpro.ru;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.fishtrackpro.ru;

    ssl_certificate     /etc/letsencrypt/live/api.fishtrackpro.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.fishtrackpro.ru/privkey.pem;

    root /var/www/fishtrackpro/public;
    index index.php;

    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $document_root;
    }

    if ($request_method = OPTIONS) {
        add_header Access-Control-Allow-Origin "https://www.fishtrackpro.ru";
        add_header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With";
        add_header Access-Control-Allow-Credentials "true";
        return 204;
    }
}
NGINX

  cat > nginx/www.fishtrackpro.ru.conf <<'NGINX'
server {
    listen 80;
    server_name fishtrackpro.ru www.fishtrackpro.ru;
    return 301 https://www.fishtrackpro.ru$request_uri;
}

server {
    listen 443 ssl http2;
    server_name www.fishtrackpro.ru;

    ssl_certificate     /etc/letsencrypt/live/www.fishtrackpro.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/www.fishtrackpro.ru/privkey.pem;

    root /var/www/fishtrackpro-web/dist;
    index index.html;

    location / {
        try_files $uri /index.html;
    }
}
NGINX

  green "✅ Nginx конфиги сгенерированы в ./nginx/"
}

# ---------- Роутер команд ----------
cmd="${1:-all}"
case "$cmd" in
  backend) backend_all ;;
  frontend) frontend_all ;;
  nginx) nginx_make ;;
  all)
    backend_all
    frontend_all
    nginx_make
    ;;
  *)
    red "Неизвестная команда: $cmd"
    echo "Использование: $0 [all|backend|frontend|nginx]"
    exit 1
    ;;
esac

green "🎣 Готово. Проверьте .env, выполните artisan команды, установите зависимости фронта и перезапустите Nginx."