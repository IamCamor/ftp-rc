<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Banner extends Model { protected $fillable=['slot_id','name','image','url','is_active','priority']; }
