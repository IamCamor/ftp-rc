<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class WeatherCache extends Model
{
    protected $table = 'weather_cache';
    protected $fillable = ['cache_key','data','expires_at'];
    protected $casts = ['data' => 'array', 'expires_at' => 'datetime'];
}
