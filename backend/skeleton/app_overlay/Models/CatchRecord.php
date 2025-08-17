<?php
namespace App\Models; use Illuminate\Database\Eloquent\Factories\HasFactory; use Illuminate\Database\Eloquent\Model;
class CatchRecord extends Model { use HasFactory; protected $fillable=['user_id','lat','lng','species','length','weight','depth','style','lure','tackle','friend_id','privacy']; }