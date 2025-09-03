<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FeedController extends Controller
{
    public function index(Request $r)
    {
        $limit  = min(max((int)$r->query('limit', 20), 1), 50);
        $offset = max((int)$r->query('offset', 0), 0);
        $near   = $r->query('near'); // "lat,lng" (опционально)

        $q = DB::table('catch_records as cr')
            ->leftJoin('users as u', 'u.id', '=', 'cr.user_id')
            ->select([
                'cr.id',
                'cr.user_id',
                DB::raw('u.name AS user_name'),
                'cr.lat','cr.lng',
                'cr.species',
                DB::raw('cr.length AS size_cm'),
                DB::raw('cr.weight AS weight_g'),
                DB::raw('cr.style AS method'),
                DB::raw('cr.tackle AS gear'),
                DB::raw('cr.lure AS bait'),
                DB::raw('cr.notes AS caption'),
                DB::raw('cr.photo_url AS media_url'),
                'cr.created_at',
                DB::raw('(SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count'),
                DB::raw('(SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id=cr.id AND (cc.is_approved=1 OR cc.is_approved IS NULL)) AS comments_count'),
            ])
            ->where('cr.privacy', 'public');

        if ($near && str_contains($near, ',')) {
            [$lat,$lng] = array_map('floatval', explode(',', $near, 2));
            // простая сортировка по «псевдо-дистанции»
            $q->orderByRaw('(ABS(cr.lat - ?) + ABS(cr.lng - ?)) ASC', [$lat, $lng]);
        } else {
            $q->orderByDesc('cr.created_at');
        }

        $rows = $q->limit($limit)->offset($offset)->get();

        $defaultAvatar = config('ui.default_avatar', '');

        // Проставляем недостающие поля на уровне PHP (без обращения к несуществующим колонкам)
        $items = $rows->map(function ($row) use ($defaultAvatar) {
            $row->user_avatar = $defaultAvatar; // т.к. колонки аватара в users нет
            $row->liked_by_me = 0;              // для гостя
            return $row;
        });

        return response()->json([
            'items'  => $items,
            'next'   => $offset + $limit,
            'limit'  => $limit,
            'offset' => $offset,
        ]);
    }
}