<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FeedController extends Controller
{
    public function index(Request $r)
    {
        $limit = (int) $r->query('limit', 20);
        $offset = (int) $r->query('offset', 0);

        $sql = "SELECT cr.id, cr.user_id, u.name as user_name, COALESCE(u.photo_url,'') as user_avatar,
                       cr.lat, cr.lng, cr.species, cr.length, cr.weight, cr.style as method, cr.lure as bait, cr.tackle as gear,
                       cr.notes as caption, cr.photo_url as media_url, cr.created_at,
                       (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count,
                       (SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id=cr.id AND (cc.is_approved=1 OR cc.is_approved IS NULL)) AS comments_count,
                       0 AS liked_by_me
                FROM catch_records cr
                LEFT JOIN users u ON u.id=cr.user_id
                WHERE cr.privacy IN ('all','friends')
                ORDER BY cr.created_at DESC
                LIMIT ? OFFSET ?";
        $items = DB::select($sql, [$limit, $offset]);

        return response()->json(['items' => $items, 'limit' => $limit, 'offset' => $offset]);
    }
}
