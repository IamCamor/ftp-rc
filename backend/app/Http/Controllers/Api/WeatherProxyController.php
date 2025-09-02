<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WeatherProxyController extends Controller
{
    public function show(Request $r)
    {
        $lat = (float) $r->query('lat');
        $lng = (float) $r->query('lng');
        $dt  = $r->query('dt'); // unix ts (опц.)
        $apiKey = config('services.openweather.key', default:'b2ec1038a1d24ac527ef79810a02b8e2');
        $base   = rtrim(config('services.openweather.base'), '/');
        $ver    = (string) config('services.openweather.version', '3.0');

        // Ответ по умолчанию — не блокирующий
        $fallback = fn($meta = []) => response()->json(array_merge([
            'source'  => $meta['source'] ?? 'none',
            'current' => null,
            'hourly'  => [],
            'daily'   => [],
            'ok'      => false,
        ], $meta), 200);

        // Нет координат — сразу мягкий ответ
        if (!$lat || !$lng) {
            return $fallback(['reason' => 'no_coords']);
        }

        // Нет ключа — мягкий ответ, без ошибок в UI
        if (!$apiKey) {
            return $fallback(['source' => 'none', 'reason' => 'no_key']);
        }

        try {
            // 1) Пытаемся One Call 3.0 (текущая/часовая/суточная в одном запросе)
            // Если пришёл dt (прошлое), One Call 3.0 требует другой endpoint/tariff.
            // Поэтому для dt используем альтернативу ниже.
            if (!$dt) {
                $url = "$base/data/$ver/onecall";
                $res = Http::timeout(6)->retry(1, 200)
                    ->get($url, [
                        'lat'   => $lat,
                        'lon'   => $lng,
                        'appid' => $apiKey,
                        'units' => 'metric',
                        'lang'  => 'ru',
                        'exclude' => 'minutely,alerts',
                    ]);

                if ($res->successful()) {
                    $json = $res->json();
                    return response()->json([
                        'source'  => 'openweather',
                        'ok'      => true,
                        'current' => $json['current'] ?? null,
                        'hourly'  => $json['hourly']  ?? [],
                        'daily'   => $json['daily']   ?? [],
                    ], 200);
                }

                // Логируем, но наружу — мягкий 200
                Log::warning('OpenWeather onecall failed', [
                    'status' => $res->status(),
                    'body'   => $res->body(),
                ]);
            }

            // 2) Фоллбек для ключей/тарифов без One Call:
            //    берём текущую и 5-дневный прогноз (2.5), собираем в единый формат
            $nowUrl = "$base/data/2.5/weather";
            $fcUrl  = "$base/data/2.5/forecast";

            $now = Http::timeout(6)->retry(1, 200)->get($nowUrl, [
                'lat'   => $lat,
                'lon'   => $lng,
                'appid' => $apiKey,
                'units' => 'metric',
                'lang'  => 'ru',
            ]);

            $fc  = Http::timeout(6)->retry(1, 200)->get($fcUrl, [
                'lat'   => $lat,
                'lon'   => $lng,
                'appid' => $apiKey,
                'units' => 'metric',
                'lang'  => 'ru',
            ]);

            if ($now->ok() || $fc->ok()) {
                $current = $now->ok() ? [
                    'dt'        => $now['dt'] ?? null,
                    'temp'      => data_get($now, 'main.temp'),
                    'pressure'  => data_get($now, 'main.pressure'),
                    'humidity'  => data_get($now, 'main.humidity'),
                    'wind_speed'=> data_get($now, 'wind.speed'),
                    'weather'   => data_get($now, 'weather.0.description'),
                    'icon'      => data_get($now, 'weather.0.icon'),
                ] : null;

                $hourly = [];
                if ($fc->ok()) {
                    foreach ($fc['list'] ?? [] as $it) {
                        $hourly[] = [
                            'dt'        => $it['dt'] ?? null,
                            'temp'      => data_get($it, 'main.temp'),
                            'pressure'  => data_get($it, 'main.pressure'),
                            'humidity'  => data_get($it, 'main.humidity'),
                            'wind_speed'=> data_get($it, 'wind.speed'),
                            'weather'   => data_get($it, 'weather.0.description'),
                            'icon'      => data_get($it, 'weather.0.icon'),
                        ];
                    }
                }

                return response()->json([
                    'source'  => 'openweather_fallback',
                    'ok'      => true,
                    'current' => $current,
                    'hourly'  => $hourly,
                    'daily'   => [], // без One Call daily нет
                ], 200);
            }

            // Если и тут не получилось — мягкий ответ
            Log::warning('OpenWeather fallback failed', [
                'now' => ['status'=>$now->status(),'body'=>$now->body()],
                'fc'  => ['status'=>$fc->status(),'body'=>$fc->body()],
            ]);
            return $fallback(['source' => 'openweather', 'reason' => 'upstream_failed', 'status' => $now->status() ?: $fc->status()]);

        } catch (ConnectionException $e) {
            Log::error('OpenWeather connection error', ['e' => $e->getMessage()]);
            return $fallback(['source'=>'openweather','reason'=>'connection_error']);
        } catch (\Throwable $e) {
            Log::error('OpenWeather unexpected error', ['e' => $e]);
            return $fallback(['source'=>'openweather','reason'=>'unexpected']);
        }
    }
}