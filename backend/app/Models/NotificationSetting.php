<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NotificationSetting extends Model
{
    protected $fillable = [
        'user_id','email_likes','email_comments','email_friends','email_system',
        'push_likes','push_comments','push_friends','push_system'
    ];
    protected $casts = [
        'email_likes'=>'boolean','email_comments'=>'boolean','email_friends'=>'boolean','email_system'=>'boolean',
        'push_likes'=>'boolean','push_comments'=>'boolean','push_friends'=>'boolean','push_system'=>'boolean'
    ];
}
