<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class WeatherController extends Controller
{
    public function show(Request $r)
    {
        $lat = (float) $r->query('lat', 55.75);
        $lng = (float) $r->query('lng', 37.62);
        $units = $r->query('units', 'metric');
        $lang = $r->query('lang', 'ru');
        $key = "lat{$lat}_lng{$lng}_{$units}_{$lang}";
        $cached = DB::table('weather_cache')->where('key', $key)->first();
        if ($cached && now()->diffInMinutes($cached->fetched_at) < 30) {
            return response()->json(['source'=>'cache','current'=>json_decode($cached->current,true),'daily'=>json_decode($cached->daily,true)]);
        }
        $apiKey = env('OPENWEATHER_KEY');
        $current = ['temp'=>18,'desc'=>'ясно']; $daily = [];
        if ($apiKey) {
            $resp = Http::get('https://api.openweathermap.org/data/2.5/onecall', [
                'lat'=>$lat, 'lon'=>$lng, 'appid'=>$apiKey, 'units'=>$units, 'lang'=>$lang, 'exclude'=>'minutely,hourly,alerts'
            ]);
            if ($resp->ok()) { $json = $resp->json(); $current = $json['current'] ?? $current; $daily = $json['daily'] ?? []; }
        }
        DB::table('weather_cache')->updateOrInsert(['key'=>$key], [
            'current'=>json_encode($current, JSON_UNESCAPED_UNICODE), 'daily'=>json_encode($daily, JSON_UNESCAPED_UNICODE),
            'fetched_at'=>now(), 'updated_at'=>now(), 'created_at'=>now()
        ]);
        return response()->json(['source'=>$apiKey?'api':'demo','current'=>$current,'daily'=>$daily]);
    }
}
