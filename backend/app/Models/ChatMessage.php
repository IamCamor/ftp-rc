<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class ChatMessage extends Model { protected $fillable=['room_id','user_id','text']; }
