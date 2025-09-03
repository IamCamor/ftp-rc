<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RatingController extends Controller
{
    public function index(Request $r)
    {
        $range = $r->query('range', 'month'); // week|month|all
        $limit = (int) $r->query('limit', 50);
        $offset = (int) $r->query('offset', 0);

        $dateCond = '';
        if ($range === 'week') {
            $dateCond = "AND cr.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
        } elseif ($range === 'month') {
            $dateCond = "AND cr.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
        }

        $sql = "
            SELECT u.id as user_id, u.name,
                   COALESCE(u.photo_url, '') as photo_url,
                   COUNT(cr.id) as catches_count,
                   COALESCE(SUM(cr.weight), 0) as total_weight,
                   COALESCE(AVG(cr.weight), 0) as avg_weight
            FROM catch_records cr
            LEFT JOIN users u ON u.id = cr.user_id
            WHERE cr.privacy IN ('all','friends') $dateCond
            GROUP BY u.id, u.name, u.photo_url
            ORDER BY catches_count DESC, total_weight DESC
            LIMIT ? OFFSET ?
        ";
        $items = DB::select($sql, [$limit, $offset]);
        // присвоим ранги
        foreach ($items as $i => $row) {
            $row->rank = $offset + $i + 1;
        }
        return response()->json(['items' => $items, 'limit' => $limit, 'offset' => $offset]);
    }
}
