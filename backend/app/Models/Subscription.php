<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Subscription extends Model { protected $fillable=['user_id','plan','period','status','renews_at','provider','provider_sub_id']; protected $casts=['renews_at'=>'datetime']; }
