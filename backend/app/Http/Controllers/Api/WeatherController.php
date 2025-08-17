<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class WeatherController extends Controller
{
    public function index(Request $r)
    {
        $lat = (float) $r->query('lat', 55.75);
        $lng = (float) $r->query('lng', 37.62);
        $lang = (string) $r->query('lang', 'ru');
        $units = (string) $r->query('units', 'metric');

        // если таблицы нет — просто отдаём мок, чтобы не падало
        $cacheEnabled = Schema::hasTable('weather_cache');

        if ($cacheEnabled) {
            $key = sprintf('owm:%0.3f,%0.3f:%s:%s', $lat, $lng, $lang, $units);
            $cached = DB::table('weather_cache')->where('key', $key)->first();
            if ($cached && now()->diffInMinutes($cached->fetched_at) < 30) {
                return response()->json([
                    'source' => 'cache',
                    'current' => json_decode($cached->current, true),
                    'daily' => json_decode($cached->daily, true),
                ]);
            }
        }

        $apiKey = config('services.openweather.key') ?: env('OPENWEATHER_API_KEY');

        // Если нет ключа — отдаём моковые данные
        if (!$apiKey) {
            return response()->json([
                'source' => 'mock',
                'current' => [
                    'temp' => 18.6, 'feels_like' => 18.0, 'humidity' => 62,
                    'wind_speed' => 3.4, 'weather' => [['description' => 'ясно']],
                ],
                'daily' => [
                    ['dt' => now()->timestamp, 'temp' => ['min' => 12, 'max' => 21]],
                    ['dt' => now()->addDay()->timestamp, 'temp' => ['min' => 13, 'max' => 22]],
                ],
            ]);
        }

        try {
            $url = 'https://api.openweathermap.org/data/3.0/onecall';
            $res = Http::timeout(6)->get($url, [
                'lat' => $lat, 'lon' => $lng, 'appid' => $apiKey,
                'units' => $units, 'lang' => $lang, 'exclude' => 'minutely,alerts',
            ]);

            if (!$res->ok()) {
                // сеть/лимиты — мягкий фолбэк
                return response()->json([
                    'source' => 'fallback-mock',
                    'message' => 'OpenWeather unavailable',
                    'status' => $res->status(),
                ], 200);
            }

            $json = $res->json();
            $current = $json['current'] ?? [];
            $daily = $json['daily'] ?? [];

            if ($cacheEnabled) {
                $payload = [
                    'current' => json_encode($current, JSON_UNESCAPED_UNICODE),
                    'daily' => json_encode($daily, JSON_UNESCAPED_UNICODE),
                    'fetched_at' => now(),
                    'updated_at' => now(),
                ];
                if (isset($key)) {
                    $exists = DB::table('weather_cache')->where('key', $key)->exists();
                    if ($exists) {
                        DB::table('weather_cache')->where('key', $key)->update($payload);
                    } else {
                        DB::table('weather_cache')->insert(array_merge($payload, [
                            'key' => $key,
                            'created_at' => now(),
                        ]));
                    }
                }
            }

            return response()->json([
                'source' => 'openweather',
                'current' => $current,
                'daily' => $daily,
            ]);
        } catch (\Throwable $e) {
            // Последний фолбэк, чтобы фронт не падал
            return response()->json([
                'source' => 'fallback-mock',
                'error' => $e->getMessage(),
                'current' => ['temp' => 19.0, 'weather' => [['description' => 'переменная облачность']]],
                'daily' => [],
            ], 200);
        }
    }
}
