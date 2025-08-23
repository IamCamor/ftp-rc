<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserBonusBalance extends Model
{
    protected $fillable = ['user_id','balance','lifetime_earned','lifetime_spent'];

    public function user(): BelongsTo {
        return $this->belongsTo(User::class);
    }
}
