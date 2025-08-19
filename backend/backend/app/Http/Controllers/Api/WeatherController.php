<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\WeatherCache;
use Carbon\Carbon;
class WeatherController extends Controller {
  public function currentPlusDaily(Request $r){
    $lat=$r->query('lat'); $lng=$r->query('lng'); $units=$r->query('units','metric'); $lang=$r->query('lang','en');
    if(!$lat||!$lng) return response()->json(['error'=>'lat/lng required'],422);
    $key=sprintf('lat:%s;lng:%s;u:%s;l:%s',$lat,$lng,$units,$lang);
    $cached=WeatherCache::where('key',$key)->first();
    if($cached && Carbon::parse($cached->fetched_at)->gt(now()->subMinutes(30))){
      return response()->json(['current'=>json_decode($cached->current,true),'daily'=>json_decode($cached->daily,true),'cached'=>true]);
    }
    $api=env('OPENWEATHER_API_KEY');
    if(!$api) return response()->json(['current'=>['temp'=>17.2,'wind_speed'=>4.1],'daily'=>[['dt'=>now()->timestamp,'temp'=>['min'=>12,'max'=>20]]],'cached'=>false]);
    $resp=Http::get('https://api.openweathermap.org/data/3.0/onecall',['lat'=>$lat,'lon'=>$lng,'units'=>$units,'lang'=>$lang,'exclude'=>'minutely,hourly,alerts','appid'=>$api]);
    if(!$resp->ok()) return response()->json(['error'=>'weather fetch failed'],500);
    $json=$resp->json();
    WeatherCache::updateOrCreate(['key'=>$key],['current'=>json_encode($json['current']??[]),'daily'=>json_encode($json['daily']??[]),'fetched_at'=>now()]);
    return response()->json(['current'=>$json['current']??[],'daily'=>$json['daily']??[],'cached'=>false]);
  }
}
