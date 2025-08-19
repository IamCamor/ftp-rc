<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Plan extends Model{ protected $fillable=['code','title','price','currency','interval','features']; protected $casts=['features'=>'array']; }
