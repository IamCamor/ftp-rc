<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class FishingPoint extends Model{ protected $fillable=['title','description','category','lat','lng','is_public','is_highlighted','photo_url','is_approved']; }
