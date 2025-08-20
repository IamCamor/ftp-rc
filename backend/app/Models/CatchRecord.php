<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class CatchRecord extends Model {
  protected $fillable=['lat','lng','fish','weight','length','style','privacy','user_id','created_at','updated_at'];
  protected $casts=['created_at'=>'datetime','updated_at'=>'datetime'];
}
