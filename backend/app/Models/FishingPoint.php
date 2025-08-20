<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class FishingPoint extends Model {
  protected $fillable=['title','type','lat','lng','is_highlighted','is_approved','photo_id'];
  protected $casts=['is_highlighted'=>'boolean','is_approved'=>'boolean'];
  public function photo(){ return $this->belongsTo(\App\Models\Media::class,'photo_id'); }
}
