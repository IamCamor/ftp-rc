<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Event extends Model{ protected $fillable=['title','region','starts_at','ends_at','description','location_lat','location_lng','link','photo_url','is_approved']; protected $casts=['starts_at'=>'datetime','ends_at'=>'datetime']; }
