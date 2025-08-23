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
