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
