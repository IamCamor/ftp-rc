<?php
namespace App\Models; use Illuminate\Database\Eloquent\Factories\HasFactory; use Illuminate\Database\Eloquent\Model;
class CatchRecord extends Model { use HasFactory; protected $fillable=['user_id','lat','lng','species','length','weight','depth','style','lure','tackle','friend_id','privacy'];
  public function likes(){ return $this->hasMany(\App\Models\CatchLike::class,'catch_id'); }
  public function comments(){ return $this->hasMany(\App\Models\CatchComment::class,'catch_id'); }
}