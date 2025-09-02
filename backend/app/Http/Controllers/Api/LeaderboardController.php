<?php
namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;

class LeaderboardController extends Controller
{
    public function index(Request $r)
    {
        $metric = $r->query('metric', 'catches'); // catches|weight|likes
        $period = $r->query('period', 'week');    // week|month|all

        $from = null;
        if ($period === 'week')  $from = now()->subWeek();
        if ($period === 'month') $from = now()->subMonth();

        $q = DB::table('catch_records as cr')
            ->selectRaw('cr.user_id, u.name, u.avatar_url,
                COUNT(*) as catches_count,
                COALESCE(SUM(cr.weight),0) as weight_total,
                COALESCE((SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id = cr.id),0) as likes_count')
            ->leftJoin('users as u','u.id','=','cr.user_id');

        if ($from) $q->where('cr.created_at','>=',$from);

        $q->groupBy('cr.user_id','u.name','u.avatar_url');

        if ($metric==='weight')    $q->orderByDesc('weight_total');
        elseif ($metric==='likes') $q->orderByDesc('likes_count');
        else                       $q->orderByDesc('catches_count');

        return response()->json($q->limit(100)->get());
    }
}
