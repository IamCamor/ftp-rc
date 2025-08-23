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
        $lat=$r->float('lat'); $lng=$r->float('lng'); $dt=$r->input('dt');
        $key = env('OPENWEATHER_KEY');
        if(!$key) return response()->json(['ok'=>false,'error'=>'OPENWEATHER_KEY missing'],500);

        if($dt){
            $url="https://api.openweathermap.org/data/3.0/onecall/timemachine";
            $resp=Http::timeout(10)->get($url,['lat'=>$lat,'lon'=>$lng,'dt'=>$dt,'appid'=>$key,'units'=>'metric','lang'=>'ru']);
        }else{
            $url="https://api.openweathermap.org/data/3.0/onecall";
            $resp=Http::timeout(10)->get($url,['lat'=>$lat,'lon'=>$lng,'appid'=>$key,'units'=>'metric','lang'=>'ru','exclude'=>'minutely,hourly,alerts']);
        }
        if(!$resp->ok()) return response()->json(['ok'=>false,'status'=>$resp->status(),'body'=>$resp->body()],502);
        return response()->json(['ok'=>true,'data'=>$resp->json()]);
    }
}
