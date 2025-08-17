<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController;
class WeatherController extends BaseController { public function current(){ return ['temp'=>20]; } public function forecast(){ return [['d1'=>18],['d2'=>22]]; } }