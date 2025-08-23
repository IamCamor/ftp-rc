#!/usr/bin/env bash
set -euo pipefail
BACK="/var/www/fishtrackpro/backend"
cd "$BACK"

echo "==> Создаю контроллеры WeatherProxyController и CatchController"
mkdir -p app/Http/Controllers/Api

cat > app/Http/Controllers/Api/WeatherProxyController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WeatherProxyController extends Controller
{
    /**
     * GET /api/v1/weather?lat=..&lng=..[&dt=unix]
     * - без dt: текущая + daily
     * - с dt: если dt в прошлом 5 дней -> timemachine, иначе возвращаем 400 c подсказкой
     */
    public function show(Request $r)
    {
        $r->validate([
            'lat'=>'required|numeric',
            'lng'=>'required|numeric',
            'dt'=>'nullable|integer'
        ]);
        $lat = (float)$r->query('lat');
        $lng = (float)$r->query('lng');
        $dt  = $r->query('dt');
        $key = env('OPENWEATHER_KEY');

        if (!$key) {
            Log::error('OPENWEATHER_KEY missing');
            return response()->json(['ok'=>false,'error'=>'OPENWEATHER_KEY missing'], 500);
        }

        try {
            if ($dt) {
                // OWM timemachine: только прошедшие даты, лимит ~5 дней
                $now = time();
                if ($dt > $now) {
                    return response()->json([
                        'ok'=>false,
                        'error'=>'dt must be in the past for timemachine'
                    ], 400);
                }
                if ($dt < ($now - 5*24*3600)) {
                    return response()->json([
                        'ok'=>false,
                        'error'=>'timemachine supports ~5 days back only'
                    ], 400);
                }

                $url = 'https://api.openweathermap.org/data/3.0/onecall/timemachine';
                $resp = Http::retry(1, 500)
                    ->timeout(10)
                    ->get($url, [
                        'lat'=>$lat,'lon'=>$lng,'dt'=>$dt,
                        'appid'=>$key,'units'=>'metric','lang'=>'ru'
                    ]);
            } else {
                // Текущая погода + daily (3.0 onecall требует подписку; если 403, fallback на 2.5)
                $url = 'https://api.openweathermap.org/data/3.0/onecall';
                $resp = Http::retry(1, 500)
                    ->timeout(10)
                    ->get($url, [
                        'lat'=>$lat,'lon'=>$lng,
                        'appid'=>$key,'units'=>'metric','lang'=>'ru',
                        'exclude'=>'minutely,hourly,alerts'
                    ]);

                if ($resp->status() == 401 || $resp->status() == 403) {
                    // fallback: current + daily из 2.5 (раздельные запросы)
                    $current = Http::timeout(8)->get(
                        'https://api.openweathermap.org/data/2.5/weather',
                        ['lat'=>$lat,'lon'=>$lng,'appid'=>$key,'units'=>'metric','lang'=>'ru']
                    );
                    $forecast = Http::timeout(8)->get(
                        'https://api.openweathermap.org/data/2.5/forecast',
                        ['lat'=>$lat,'lon'=>$lng,'appid'=>$key,'units'=>'metric','lang'=>'ru']
                    );
                    if (!$current->ok()) {
                        return response()->json(['ok'=>false,'status'=>$current->status(),'body'=>$current->body()], 502);
                    }
                    // daily в 2.5 отсутствует — вернём forecast list (3‑часовые)
                    return response()->json([
                        'ok'=>true,
                        'data'=>[
                            'current'=>$current->json(),
                            'forecast'=>$forecast->ok() ? $forecast->json() : null
                        ],
                        'fallback'=>'2.5'
                    ]);
                }
            }

            if (!$resp->ok()) {
                Log::error('OWM error', ['status'=>$resp->status(),'body'=>$resp->body()]);
                return response()->json(['ok'=>false,'status'=>$resp->status(),'body'=>$resp->body()], 502);
            }

            return response()->json(['ok'=>true,'data'=>$resp->json()]);
        } catch (\Throwable $e) {
            Log::error('WeatherProxy exception: '.$e->getMessage(), ['trace'=>$e->getTraceAsString()]);
            return response()->json(['ok'=>false,'error'=>'weather_unavailable'], 502);
        }
    }
}
PHP

cat > app/Http/Controllers/Api/CatchController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CatchController extends Controller
{
    // GET /api/v1/catches?limit=20&offset=0
    public function index(Request $r)
    {
        $limit = min(50,(int)$r->query('limit',20));
        $offset = max(0,(int)$r->query('offset',0));

        $items = DB::table('catch_records AS cr')
            ->leftJoin('users AS u','u.id','=','cr.user_id')
            ->selectRaw("
                cr.id, cr.user_id,
                COALESCE(u.name,'Рыбак') AS user_name,
                '' AS user_avatar,
                cr.lat, cr.lng, cr.species, cr.length, cr.weight,
                cr.style, cr.lure, cr.tackle, cr.notes, cr.photo_url,
                COALESCE(cr.caught_at, cr.created_at) AS created_at,
                (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count,
                (SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id=cr.id) AS comments_count
            ")
            ->where('cr.privacy','all')
            ->orderByDesc('created_at')
            ->orderByDesc('cr.id')
            ->limit($limit)
            ->offset($offset)
            ->get();

        return response()->json([
            'items'=>$items,
            'next_offset'=>$offset + $items->count()
        ]);
    }

    // POST /api/v1/catches  (без авторизации для тестов — приведите под middleware позже)
    public function store(Request $r)
    {
        $data = $r->validate([
            'user_id'   => 'nullable|integer|exists:users,id',
            'lat'       => 'required|numeric',
            'lng'       => 'required|numeric',
            'species'   => 'nullable|string|max:255',
            'length'    => 'nullable|numeric',
            'weight'    => 'nullable|numeric',
            'style'     => 'nullable|string|max:255',
            'lure'      => 'nullable|string|max:255',
            'tackle'    => 'nullable|string|max:255',
            'notes'     => 'nullable|string',
            'photo_url' => 'nullable|string|max:255',
            'caught_at' => 'nullable|date'
        ]);

        // privacy только из допустимых: all/friends/private — используем all по умолчанию
        $privacy = $r->string('privacy','all');
        if (!in_array($privacy, ['all','friends','private'])) $privacy = 'all';

        $id = DB::table('catch_records')->insertGetId([
            'user_id'   => $data['user_id'] ?? null,
            'lat'       => $data['lat'],
            'lng'       => $data['lng'],
            'species'   => $data['species'] ?? null,
            'length'    => $data['length'] ?? null,
            'weight'    => $data['weight'] ?? null,
            'style'     => $data['style'] ?? null,
            'lure'      => $data['lure'] ?? null,
            'tackle'    => $data['tackle'] ?? null,
            'notes'     => $data['notes'] ?? null,
            'photo_url' => $data['photo_url'] ?? null,
            'caught_at' => $data['caught_at'] ?? null,
            'privacy'   => $privacy,
            'created_at'=> now(),
            'updated_at'=> now(),
        ]);

        $row = DB::table('catch_records')->where('id',$id)->first();
        return response()->json(['ok'=>true,'item'=>$row], 201);
    }
}
PHP

echo "==> Обновляю routes/api.php (добавляю weather и catches)"
cat > routes/api.php <<'PHP'
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\WeatherProxyController;
use App\Http\Controllers\Api\CatchController;

Route::get('/health', fn()=>response()->json(['ok'=>true,'ts'=>now()]));

Route::prefix('v1')->group(function () {
    // Погода (OWM прокси)
    Route::get('/weather', [WeatherProxyController::class,'show']);

    // Лента уловов и создание улова
    Route::get('/catches', [CatchController::class,'index']);
    Route::post('/catches', [CatchController::class,'store']);
});
PHP

echo "==> Composer dump + очистка кешей"
composer dump-autoload -q || true
php artisan optimize:clear

echo "==> Готово. Проверьте ключ OPENWEATHER_KEY в .env. Примеры:"
echo "curl -i 'https://api.fishtrackpro.ru/api/v1/weather?lat=55.7558&lng=37.6173'"
echo "curl -i 'https://api.fishtrackpro.ru/api/v1/catches?limit=5'"