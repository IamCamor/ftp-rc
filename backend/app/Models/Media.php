<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Media extends Model {
  protected $fillable = ['model_type','model_id','disk','path','mime','size'];
  protected $appends = ['url'];
  public function getUrlAttribute(){ return \Storage::disk($this->disk)->url($this->path); }
}