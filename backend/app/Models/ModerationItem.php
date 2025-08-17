<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class ModerationItem extends Model {
  protected $table='moderation_queue';
  protected $fillable=['type','ref_id','payload','status','provider','result'];
  protected $casts=['payload'=>'array','result'=>'array'];
}