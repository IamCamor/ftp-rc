<?php
namespace App\Models; use Illuminate\Database\Eloquent\Model; use Illuminate\Database\Eloquent\Factories\HasFactory;
class CustomNotification extends Model { use HasFactory; protected $table='notifications_custom'; protected $fillable=['user_id','type','data','read']; protected $casts=['data'=>'array']; }