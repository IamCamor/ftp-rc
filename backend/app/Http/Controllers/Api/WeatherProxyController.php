<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class WeatherProxyController extends Controller
{
    public function show(Request $r)
    {
        $lat = (float) $r->query('lat');
        $lng = (float) $r->query('lng');
        $dt  = $r->query('dt'); // timestamp (опц.)

        if (!$lat || !$lng) {
            return response()->json(['error' => 'lat/lng required'], 400);
        }

        $apiKey = env('OPENWEATHER_KEY');
        if (!$apiKey) {
            // Без ключа — не блокируем сохранение: возвращаем «пустую» погоду.
            return response()->json([
                'source' => 'none',
                'current' => null,
                'hourly' => [],
                'daily'  => [],
            ], 200);
        }

        // One Call 3.0 (исторические по dt — через timemachine, иначе current/forecast)
        try {
            if ($dt) {
                $res = Http::timeout(10)->get('https://api.openweathermap.org/data/3.0/onecall/timemachine', [
                    'lat' => $lat,
                    'lon' => $lng,
                    'dt'  => (int)$dt,
                    'appid' => $apiKey,
                    'units' => 'metric',
                    'lang' => 'ru',
                ]);
            } else {
                $res = Http::timeout(10)->get('https://api.openweathermap.org/data/3.0/onecall', [
                    'lat' => $lat,
                    'lon' => $lng,
                    'appid' => $apiKey,
                    'units' => 'metric',
                    'lang' => 'ru',
                    'exclude' => 'minutely,alerts',
                ]);
            }

            if ($res->failed()) {
                return response()->json([
                    'source' => 'openweather',
                    'error'  => 'upstream_failed',
                    'status' => $res->status(),
                ], 200);
            }

            $data = $res->json() ?? [];
            $out = [
                'source'  => 'openweather',
                'current' => $data['current'] ?? null,
                'hourly'  => $data['hourly'] ?? [],
                'daily'   => $data['daily'] ?? [],
            ];
            // Простые производные поля (давление, ветер и т.п.) если есть current
            if (!empty($out['current'])) {
                $c = $out['current'];
                $out['quick'] = [
                    'temp'      => $c['temp']      ?? null,
                    'pressure'  => $c['pressure']  ?? null,
                    'wind_speed'=> $c['wind_speed']?? null,
                    'wind_deg'  => $c['wind_deg']  ?? null,
                    'humidity'  => $c['humidity']  ?? null,
                    'clouds'    => $c['clouds']    ?? null,
                    'weather'   => $c['weather'][0]['description'] ?? null,
                ];
            }

            return response()->json($out, 200);

        } catch (\Throwable $e) {
            // Лог, но клиенту — мягкий ответ
            report($e);
            return response()->json([
                'source' => 'none',
                'current' => null,
                'hourly' => [],
                'daily'  => [],
            ], 200);
        }
    }
}