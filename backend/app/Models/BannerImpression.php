<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class BannerImpression extends Model { protected $fillable=['banner_id','user_id','session','ip']; }
