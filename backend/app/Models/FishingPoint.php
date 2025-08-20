<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class FishingPoint extends Model {
  protected $fillable=['title','type','lat','lng','is_highlighted','is_approved'];
  protected $casts=['is_highlighted'=>'boolean','is_approved'=>'boolean'];
}
