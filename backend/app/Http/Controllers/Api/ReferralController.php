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
