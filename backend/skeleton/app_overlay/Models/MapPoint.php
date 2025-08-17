<?php
namespace App\Models; use Illuminate\Database\Eloquent\Factories\HasFactory; use Illuminate\Database\Eloquent\Model;
class MapPoint extends Model { use HasFactory; protected $fillable=['title','description','lat','lng','type','is_featured','visibility']; }