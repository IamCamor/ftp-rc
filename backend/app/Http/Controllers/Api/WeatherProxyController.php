<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class WeatherProxyController extends Controller
{
    public function show(Request $r)
    {
        $lat = (float) $r->query('lat', 0);
        $lng = (float) $r->query('lng', 0);
        $dt  = $r->query('dt'); // optional unix
        $key = env('OPENWEATHER_KEY', '');

        if ($lat === 0 && $lng === 0) {
            return response()->json(['source' => 'openweather', 'error' => 'bad_coords'], 200);
        }
        if ($key === '') {
            return response()->json(['source' => 'openweather', 'error' => 'missing_key'], 200);
        }

        $endpoint = $dt ? 'timemachine' : 'weather';
        // For timemachine, OpenWeather new endpoint is One Call 3.0; here we keep simple try for compatibility.
        $url = $dt
            ? "https://api.openweathermap.org/data/3.0/onecall/timemachine?lat={$lat}&lon={$lng}&dt={$dt}&appid={$key}&units=metric&lang=ru"
            : "https://api.openweathermap.org/data/2.5/weather?lat={$lat}&lon={$lng}&appid={$key}&units=metric&lang=ru";

        try {
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT => 10,
            ]);
            $body = curl_exec($ch);
            $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            if ($body === false) {
                $err = curl_error($ch);
                curl_close($ch);
                return response()->json(['source'=>'openweather','error'=>'curl','message'=>$err], 200);
            }
            curl_close($ch);

            if ($code >= 400) {
                return response()->json(['source'=>'openweather','error'=>'upstream_failed','status'=>$code], 200);
            }
            $json = json_decode($body, true);
            if (!is_array($json)) {
                return response()->json(['source'=>'openweather','error'=>'bad_json'], 200);
            }
            return response()->json(['source'=>'openweather','data'=>$json], 200);
        } catch (\Throwable $e) {
            return response()->json(['source'=>'openweather','error'=>'exception','message'=>$e->getMessage()], 200);
        }
    }
}
