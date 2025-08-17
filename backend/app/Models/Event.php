<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Event extends Model { protected $fillable=['title','description','starts_at','ends_at','region','creator_id']; protected $casts=['starts_at'=>'datetime','ends_at'=>'datetime']; }
