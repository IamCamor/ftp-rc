#!/usr/bin/env bash
set -euo pipefail

# Проверка, что мы в корне backend
if [[ ! -f artisan ]]; then
  echo "❌ Не найден artisan. Запустите из каталога backend."
  exit 1
fi

echo "▶️ Создаю каталоги..."
mkdir -p app/Services app/Observers app/Http/Controllers/Api app/Console/Commands

############################################
# Services: PointsService (S1+S2 стрики/лимиты)
############################################
cat > app/Services/PointsService.php <<'PHP'
<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Carbon;

class PointsService
{
    /** Дневные лимиты по событиям (только для положительных начислений) */
    private const DAILY_CAPS = [
        'catch_create'      => 10,
        'place_create'      => 5,
        'comment_create'    => 20,
        'comment_received'  => 100,
        'like_giver'        => 50,
        'like_received'     => 200,
        'referral_bonus'    => 1,   // уникальное событие
        'daily_award'       => 1,
    ];

    /** Список событий, которые двигают «стрик» (S2) */
    private const STREAK_REASONS = [
        'catch_create', 'place_create', 'comment_create',
    ];

    /**
     * Идемпотентное начисление баллов.
     */
    public function award(
        int $userId,
        int $delta,
        string $reason,
        ?string $refType = null,
        ?int $refId = null,
        array $meta = [],
        ?string $idempotencyKey = null
    ): void {
        if ($delta === 0) return;

        DB::transaction(function () use ($userId, $delta, $reason, $refType, $refId, $meta, $idempotencyKey) {
            if ($idempotencyKey) {
                $exists = DB::table('points_ledger')->where('idempotency_key', $idempotencyKey)->exists();
                if ($exists) return;
            }

            // Применяем дневные лимиты только на +баллы
            $applyDelta = $delta;
            if ($delta > 0 && isset(self::DAILY_CAPS[$reason])) {
                $today = Carbon::today();
                $usedToday = (int) DB::table('points_ledger')
                    ->where('user_id', $userId)
                    ->where('reason_code', $reason)
                    ->whereDate('created_at', $today)
                    ->sum('delta');
                $remaining = max(0, self::DAILY_CAPS[$reason] - $usedToday);
                $applyDelta = min($delta, $remaining);
                if ($applyDelta <= 0) return; // лимит исчерпан
            }

            // upsert user_points
            $row = DB::table('user_points')->where('user_id', $userId)->lockForUpdate()->first();
            if (!$row) {
                DB::table('user_points')->insert([
                    'user_id'      => $userId,
                    'balance_bp'   => 0,
                    'lifetime_bp'  => 0,
                    'streak_days'  => 0,
                    'streak_updated_at' => null,
                    'last_daily_award_at' => null,
                    'created_at'   => now(),
                    'updated_at'   => now(),
                ]);
                $row = (object)[
                    'balance_bp' => 0,
                    'lifetime_bp'=> 0,
                    'streak_days'=> 0,
                    'streak_updated_at' => null,
                ];
            }

            // баланс/накопления
            $newBalance  = (int)$row->balance_bp + $applyDelta;
            $newLifetime = (int)$row->lifetime_bp + max($applyDelta, 0);

            DB::table('user_points')->where('user_id', $userId)->update([
                'balance_bp'  => $newBalance,
                'lifetime_bp' => $newLifetime,
                'updated_at'  => now(),
            ]);

            // запись в журнал
            DB::table('points_ledger')->insert([
                'user_id'         => $userId,
                'delta'           => $applyDelta,
                'reason_code'     => $reason,
                'ref_type'        => $refType,
                'ref_id'          => $refId,
                'idempotency_key' => $idempotencyKey,
                'meta'            => json_encode($meta, JSON_UNESCAPED_UNICODE),
                'created_at'      => now(),
            ]);

            // Стрик (S2): инкремент, если сегодня ещё не отмечался
            if ($applyDelta > 0 && in_array($reason, self::STREAK_REASONS, true)) {
                $today = Carbon::today();
                $last  = $row->streak_updated_at ? Carbon::parse($row->streak_updated_at) : null;

                $newStreak = (int)$row->streak_days;
                if (!$last) {
                    $newStreak = 1;
                } elseif ($last->isSameDay($today)) {
                    // уже отмечали сегодня — ничего
                } elseif ($last->isYesterday()) {
                    $newStreak += 1;
                } else {
                    $newStreak = 1;
                }

                DB::table('user_points')->where('user_id', $userId)->update([
                    'streak_days'      => $newStreak,
                    'streak_updated_at'=> now(),
                    'updated_at'       => now(),
                ]);
            }
        });
    }

    /**
     * Реверс начислений по сущности (S3 — модерация).
     */
    public function revertForEntity(string $refType, int $refId, array $reasons = []): void
    {
        DB::transaction(function () use ($refType, $refId, $reasons) {
            $qb = DB::table('points_ledger')->where('ref_type', $refType)->where('ref_id', $refId);
            if (!empty($reasons)) $qb->whereIn('reason_code', $reasons);
            $txs = $qb->lockForUpdate()->get();

            foreach ($txs as $t) {
                // откатим суммой обратного знака
                $this->award(
                    (int)$t->user_id,
                    -(int)$t->delta,
                    'moderation_revert',
                    $refType,
                    (int)$refId,
                    ['orig_reason' => $t->reason_code]
                );
            }
        });
    }
}
PHP

############################################
# Services: ReferralService (S3)
############################################
cat > app/Services/ReferralService.php <<'PHP'
<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class ReferralService
{
    /** Код = base36(user_id) */
    public function codeFor(int $userId): string
    {
        return strtoupper(base_convert((string)$userId, 10, 36));
    }

    public function decode(string $code): ?int
    {
        $code = strtoupper(trim($code));
        if (!preg_match('/^[A-Z0-9]+$/', $code)) return null;
        $id = base_convert($code, 36, 10);
        return is_numeric($id) ? (int)$id : null;
    }

    /** Сохраняет связку inviter→invitee (без повторов) */
    public function link(int $inviterId, int $inviteeId): bool
    {
        if ($inviterId === $inviteeId) return false;
        $exists = DB::table('referrals')->where(['inviter_id'=>$inviterId, 'invitee_id'=>$inviteeId])->exists();
        if ($exists) return false;

        DB::table('referrals')->insert([
            'inviter_id' => $inviterId,
            'invitee_id' => $inviteeId,
            'awarded_at' => null,
        ]);
        return true;
    }

    /**
     * Наградить пригласившего и приглашённого при «первом контенте» приглашённого.
     * Срабатывает из Observer улова/места.
     */
    public function tryAwardOnFirstContent(int $inviteeId, string $refType, int $refId): void
    {
        $ref = DB::table('referrals')->where('invitee_id', $inviteeId)->whereNull('awarded_at')->lockForUpdate()->first();
        if (!$ref) return;

        $ps = app(\App\Services\PointsService::class);
        $idem = "ref_bonus:{$inviteeId}";
        $ps->award((int)$ref->inviter_id, +50, 'referral_bonus', $refType, $refId, ['invitee'=>$inviteeId], $idem.":inv");
        $ps->award($inviteeId,           +20, 'referral_bonus', $refType, $refId, ['inviter'=>$ref->inviter_id], $idem.":intee");

        DB::table('referrals')->where('id', $ref->id)->update(['awarded_at'=>now()]);
    }
}
PHP

############################################
# Observers (S1, S3)
############################################
cat > app/Observers/CatchRecordObserver.php <<'PHP'
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
PHP

cat > app/Observers/FishingPointObserver.php <<'PHP'
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
PHP

############################################
# Controllers: PointsController (S1), ReferralController (S3)
############################################
cat > app/Http/Controllers/Api/PointsController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PointsController extends Controller
{
    public function me(Request $r)
    {
        $user = $r->user();
        if (!$user) return response()->json(['message'=>'Unauthorized'], 401);

        $row = DB::table('user_points')->where('user_id', (int)$user->id)->first();

        return response()->json([
            'balance'     => (int)($row->balance_bp ?? 0),
            'lifetime'    => (int)($row->lifetime_bp ?? 0),
            'streak_days' => (int)($row->streak_days ?? 0),
        ]);
    }

    public function ledger(Request $r)
    {
        $user = $r->user();
        if (!$user) return response()->json(['message'=>'Unauthorized'], 401);

        $page = max(1, (int)$r->input('page', 1));
        $per  = min(50, max(10, (int)$r->input('per', 20)));

        $items = DB::table('points_ledger')
            ->where('user_id', (int)$user->id)
            ->orderByDesc('id')
            ->forPage($page, $per)
            ->get();

        return response()->json(['items'=>$items, 'page'=>$page, 'per'=>$per]);
    }
}
PHP

cat > app/Http/Controllers/Api/ReferralController.php <<'PHP'
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\ReferralService;
use Illuminate\Http\Request;

class ReferralController extends Controller
{
    public function myCode(Request $r, ReferralService $ref)
    {
        $user = $r->user();
        if (!$user) return response()->json(['message'=>'Unauthorized'], 401);

        return response()->json(['code' => $ref->codeFor((int)$user->id)]);
    }

    public function link(Request $r, ReferralService $ref)
    {
        $user = $r->user();
        if (!$user) return response()->json(['message'=>'Unauthorized'], 401);

        $code = (string)$r->input('code', '');
        $inviterId = $ref->decode($code);
        if (!$inviterId) return response()->json(['message'=>'Bad code'], 422);

        $ok = $ref->link((int)$inviterId, (int)$user->id);
        return response()->json(['linked' => (bool)$ok]);
    }
}
PHP

############################################
# Регистрация Observers в AppServiceProvider
############################################
if grep -q "CatchRecord::class" app/Providers/AppServiceProvider.php 2>/dev/null; then
  echo "ℹ️ Observers уже упоминались в AppServiceProvider.php — пропускаю вставку."
else
  cat > app/Providers/AppServiceProvider.php.tmp <<'PHP'
<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // Регистрация наблюдателей,
        // только если модели существуют в проекте:
        if (class_exists(\App\Models\CatchRecord::class) && class_exists(\App\Observers\CatchRecordObserver::class)) {
            \App\Models\CatchRecord::observe(\App\Observers\CatchRecordObserver::class);
        }
        if (class_exists(\App\Models\FishingPoint::class) && class_exists(\App\Observers\FishingPointObserver::class)) {
            \App\Models\FishingPoint::observe(\App\Observers\FishingPointObserver::class);
        }
    }
}
PHP
  mv app/Providers/AppServiceProvider.php.tmp app/Providers/AppServiceProvider.php
fi

############################################
# Маршруты API (S1 + S3)
############################################
ROUTES_FILE="routes/api.php"
if ! grep -q "points/me" "$ROUTES_FILE"; then
  cat >> "$ROUTES_FILE" <<'PHP'

/* ==== Bonus Points API (S1–S3) ==== */
use App\Http\Controllers\Api\PointsController;
use App\Http\Controllers\Api\ReferralController;

Route::prefix('v1')->group(function () {
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('points/me', [PointsController::class, 'me']);
        Route::get('points/ledger', [PointsController::class, 'ledger']);

        Route::get('referral/code', [ReferralController::class, 'myCode']);
        Route::post('referral/link', [ReferralController::class, 'link']); // body: {code}
    });
});
PHP
else
  echo "ℹ️ Маршруты points/referral уже добавлены — пропускаю."
fi

echo "🧹 Очистка кэшей..."
php artisan optimize:clear || true

echo "✅ Готово. Теперь выполните SQL из файла points_schema.sql (см. ниже) и перезапустите PHP-FPM."