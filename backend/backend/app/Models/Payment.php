<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Payment extends Model{ protected $fillable=['user_id','provider','status','amount','currency','external_id','payload']; protected $casts=['payload'=>'array']; }
