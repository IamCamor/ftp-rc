<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BonusTransaction extends Model
{
    protected $fillable = ['user_id','action_code','amount','meta'];
    protected $casts = ['amount'=>'integer'];

    public function user(): BelongsTo {
        return $this->belongsTo(User::class);
    }
}
