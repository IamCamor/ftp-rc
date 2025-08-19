<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Club extends Model{ protected $fillable=['name','region','description','logo_url','is_approved']; }
