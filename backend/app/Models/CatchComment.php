<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class CatchComment extends Model {
  protected $table = 'catch_comments';
  protected $fillable = ['catch_id','user_id','text','status','body','is_approved'];

  public function getTextAttribute($value){
    if ($value !== null) return $value;
    return $this->attributes['body'] ?? null;
  }
  public function setTextAttribute($value){
    $this->attributes['text'] = $value;
    $this->attributes['body'] = $value;
  }
  public function getStatusAttribute($value){
    if ($value !== null) return $value;
    $approved = $this->attributes['is_approved'] ?? 1;
    return $approved ? 'approved' : 'pending';
  }
  public function setStatusAttribute($value){
    $this->attributes['status'] = $value;
    $this->attributes['is_approved'] = ($value === 'approved') ? 1 : 0;
  }
}
