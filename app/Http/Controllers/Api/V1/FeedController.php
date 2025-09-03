<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\CatchResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FeedController extends Controller
{
    public function index(Request $request)
    {
        $limit = (int)($request->query('limit', 20));
        $offset = (int)($request->query('offset', 0));
        $viewerId = $request->user()?->id;

        $sql = "
            SELECT 
                cr.id,
                cr.user_id,
                u.name AS user_name,
                u.avatar_path AS user_avatar_path,
                cr.lat, cr.lng, cr.species, cr.length, cr.weight, cr.depth,
                cr.style, cr.lure, cr.tackle,
                cr.water_type, cr.water_temp, cr.wind_speed, cr.pressure,
                cr.companions,
                cr.notes, cr.photo_url, cr.privacy, cr.caught_at,
                cr.created_at,
                (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count,
                (SELECT COUNT(*) FROM catch_comments cc 
                    WHERE cc.catch_id=cr.id 
                      AND (cc.is_approved=1 OR cc.is_approved IS NULL)
                ) AS comments_count,
                " . ($viewerId ? "EXISTS(SELECT 1 FROM catch_likes cl2 WHERE cl2.catch_id=cr.id AND cl2.user_id=?)" : "0") . " AS liked_by_me
            FROM catch_records cr
            LEFT JOIN users u ON u.id = cr.user_id
            WHERE 
                (
                    cr.privacy = 'all'
                    OR (
                        cr.privacy = 'friends' 
                        AND " . ($viewerId ? "EXISTS(SELECT 1 FROM friendships f
                              WHERE ((f.user_id = cr.user_id AND f.friend_id = ?) OR (f.user_id = ? AND f.friend_id = cr.user_id))
                                AND f.status = 'accepted')" : "0") . "
                    )
                )
            ORDER BY cr.created_at DESC
            LIMIT ? OFFSET ?
        ";

        $bindings = [];
        if ($viewerId) {
            $bindings[] = $viewerId;
            $bindings[] = $viewerId;
            $bindings[] = $viewerId;
        }
        $bindings[] = $limit;
        $bindings[] = $offset;

        $rows = DB::select($sql, $bindings);

        return CatchResource::collection(collect($rows));
    }
}
