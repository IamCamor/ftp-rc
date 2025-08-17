<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Payment extends Model { protected $fillable=['user_id','provider','intent_id','status','currency','amount','purpose','metadata']; protected $casts=['metadata'=>'array','amount'=>'decimal:2']; }
