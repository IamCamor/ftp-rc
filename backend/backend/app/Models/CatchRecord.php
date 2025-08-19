<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class CatchRecord extends Model{ protected $table='catches'; protected $fillable=['lat','lng','species','length','weight','depth','style','lure','tackle','privacy','companions','notes','caught_at','is_approved']; protected $casts=['caught_at'=>'datetime']; }
