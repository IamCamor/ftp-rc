#!/usr/bin/env bash
set -euo pipefail

BACK="./backend"

cd backend

echo "==> Создаю контроллеры WeatherProxyController и FeedController (безопасные поля)"
mkdir -p app/Http/Controllers/Api

# WeatherProxyController
cat > app/Http/Controllers/Api/WeatherProxyController.php <<'PHP'
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
        $lat=(float)$r->query('lat'); $lng=(float)$r->query('lng'); $dt=$r->query('dt');
        $key = env('OPENWEATHER_KEY');
        if(!$key){ return response()->json(['ok'=>false,'error'=>'OPENWEATHER_KEY missing'],500); }

        if($dt){
            $url="https://api.openweathermap.org/data/3.0/onecall/timemachine";
            $resp=Http::timeout(10)->get($url,[
              'lat'=>$lat,'lon'=>$lng,'dt'=>$dt,
              'appid'=>$key,'units'=>'metric','lang'=>'ru'
            ]);
        }else{
            $url="https://api.openweathermap.org/data/3.0/onecall";
            $resp=Http::timeout(10)->get($url,[
              'lat'=>$lat,'lon'=>$lng,
              'appid'=>$key,'units'=>'metric','lang'=>'ru',
              'exclude'=>'minutely,hourly,alerts'
            ]);
        }
        if(!$resp->ok()){
            return response()->json(['ok'=>false,'status'=>$resp->status(),'body'=>$resp->body()],502);
        }
        return response()->json(['ok'=>true,'data'=>$resp->json()]);
    }
}
PHP

# FeedController — только существующие поля таблиц
cat > app/Http/Controllers/Api/FeedController.php <<'PHP'
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
        $userId  = $r->query('user_id');
        $placeId = $r->query('place_id');

        $q = DB::table('catch_records AS cr')
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
            ->where('cr.privacy','all');

        if($species) $q->where('cr.species','like','%'.$species.'%');
        if($userId)  $q->where('cr.user_id',(int)$userId);

        if($placeId){
            $p = DB::table('fishing_points')->where('id',(int)$placeId)->first();
            if($p){
                $lat0=$p->lat; $lng0=$p->lng; $km=2.0;
                $q->whereRaw(
                  "(6371*ACOS( COS(RADIANS(?))*COS(RADIANS(cr.lat))*COS(RADIANS(cr.lng)-RADIANS(?)) + SIN(RADIANS(?))*SIN(RADIANS(cr.lat)) )) <= ?",
                  [$lat0,$lng0,$lat0,$km]
                );
            }
        }

        $items = $q->orderByDesc('created_at')->orderByDesc('cr.id')
                   ->limit($limit)->offset($offset)->get();

        return response()->json([
            'items'=>$items,
            'next_offset'=>$offset + $items->count()
        ]);
    }
}
PHP

echo "==> Обновляю routes/api.php — добавляю /api/v1/weather и /api/v1/feed"
ROUTES="$BACK/routes/api.php"
cp "$ROUTES" "$ROUTES.bak.$(date +%s)" || true

# Вставляем (или переопределяем) блок v1 с нужными маршрутами
cat > "$ROUTES" <<'PHP'
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\WeatherProxyController;
use App\Http\Controllers\Api\FeedController;

Route::get('/health', fn()=>response()->json(['ok'=>true,'ts'=>now()]));

// Не трогаем остальное API, добавляем недостающие endpoints:
Route::prefix('v1')->group(function () {
    Route::get('/weather',[WeatherProxyController::class,'show']);
    Route::get('/feed',[FeedController::class,'index']);
});
PHP

echo "==> Composer autoload + сброс кэшей"
composer dump-autoload -q || true
php artisan optimize:clear

echo "==> Готово. Сейчас проверим наличие роутов:"
php artisan route:list | grep -E "v1/(weather|feed)" || true

echo "==> Напоминание: в .env должен быть OPENWEATHER_KEY=<ключ>"