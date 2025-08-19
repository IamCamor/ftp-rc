<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class WeatherCache extends Model{ protected $table='weather_cache'; protected $fillable=['key','current','daily','fetched_at']; protected $casts=['fetched_at'=>'datetime']; }
