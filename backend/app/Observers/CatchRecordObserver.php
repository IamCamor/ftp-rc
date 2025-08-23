<?php

namespace App\Observers;

use App\Models\CatchRecord;
use App\Services\PointsService;
use App\Services\ReferralService;

class CatchRecordObserver
{
    public function created(CatchRecord $catch): void
    {
        $uid = (int)($catch->user_id ?? 0);
        if ($uid <= 0) return;

        $delta = 15;
        if (!empty($catch->photo_url)) $delta += 2;
        if (!empty($catch->weight) || !empty($catch->length)) $delta += 2;
        if (!empty($catch->species)) $delta += 2;

        app(PointsService::class)->award(
            $uid, $delta, 'catch_create', 'catch', (int)$catch->id,
            ['auto'=>'observer'], "catch_create:{$catch->id}"
        );

        // Реферальный бонус (S3): за первый контент приглашённого
        app(ReferralService::class)->tryAwardOnFirstContent($uid, 'catch', (int)$catch->id);
    }

    public function deleted(CatchRecord $catch): void
    {
        app(PointsService::class)->revertForEntity('catch', (int)$catch->id, ['catch_create']);
    }
}
