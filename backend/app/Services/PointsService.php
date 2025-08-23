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
