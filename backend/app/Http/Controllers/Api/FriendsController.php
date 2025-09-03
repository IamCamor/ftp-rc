<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FriendsController extends Controller
{
    // Список друзей (взаимная подписка) / подписок / подписчиков
    public function index(Request $r)
    {
        $userId = (int) ($r->query('userId', auth()->id() ?? 0));
        $scope = $r->query('scope', 'mutual'); // mutual|following|followers
        $limit = (int) $r->query('limit', 50);
        $offset = (int) $r->query('offset', 0);

        if ($scope === 'following') {
            $sql = "SELECT u.id, u.name, COALESCE(u.photo_url,'') as photo_url
                    FROM follows f
                    JOIN users u ON u.id=f.followee_id
                    WHERE f.follower_id=?
                    ORDER BY u.name ASC
                    LIMIT ? OFFSET ?";
            $items = DB::select($sql, [$userId, $limit, $offset]);
        } elseif ($scope === 'followers') {
            $sql = "SELECT u.id, u.name, COALESCE(u.photo_url,'') as photo_url
                    FROM follows f
                    JOIN users u ON u.id=f.follower_id
                    WHERE f.followee_id=?
                    ORDER BY u.name ASC
                    LIMIT ? OFFSET ?";
            $items = DB::select($sql, [$userId, $limit, $offset]);
        } else { // mutual
            $sql = "SELECT u.id, u.name, COALESCE(u.photo_url,'') as photo_url
                    FROM follows a
                    JOIN follows b ON a.followee_id=b.follower_id AND a.follower_id=b.followee_id
                    JOIN users u ON u.id=a.followee_id
                    WHERE a.follower_id=?
                    GROUP BY u.id, u.name, u.photo_url
                    ORDER BY u.name ASC
                    LIMIT ? OFFSET ?";
            $items = DB::select($sql, [$userId, $limit, $offset]);
        }

        return response()->json(['items' => $items, 'limit' => $limit, 'offset' => $offset]);
    }

    // Рекомендации друзей (простая версия)
    public function suggest(Request $r)
    {
        $limit = (int) $r->query('limit', 20);
        $items = DB::select("
            SELECT u.id, u.name, COALESCE(u.photo_url,'') as photo_url
            FROM users u
            ORDER BY u.created_at DESC
            LIMIT ?", [$limit]);
        return response()->json(['items' => $items]);
    }
}
