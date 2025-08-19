<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class NotificationSetting extends Model{ protected $fillable=['user_id','push_enabled','email_enabled','likes_enabled','comments_enabled','system_enabled']; protected $casts=['push_enabled'=>'boolean','email_enabled'=>'boolean','likes_enabled'=>'boolean','comments_enabled'=>'boolean','system_enabled'=>'boolean']; }
