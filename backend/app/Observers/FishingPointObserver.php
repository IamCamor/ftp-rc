<?php

namespace App\Observers;

use App\Models\FishingPoint;
use App\Services\PointsService;
use App\Services\ReferralService;

class FishingPointObserver
{
    public function created(FishingPoint $point): void
    {
        $uid = (int)($point->user_id ?? 0);
        if ($uid <= 0) return;

        $delta = 20;
        if (!empty($point->description)) $delta += 2;

        app(PointsService::class)->award(
            $uid, $delta, 'place_create', 'place', (int)$point->id,
            ['auto'=>'observer'], "place_create:{$point->id}"
        );

        app(ReferralService::class)->tryAwardOnFirstContent($uid, 'place', (int)$point->id);
    }

    public function deleted(FishingPoint $point): void
    {
        app(PointsService::class)->revertForEntity('place', (int)$point->id, ['place_create']);
    }
}
