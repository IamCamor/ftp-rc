<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class FeedController extends Controller
{
    public function index(Request $r)
    {
        $limit  = min(max((int)$r->query('limit', 20), 1), 50);
        $offset = max((int)$r->query('offset', 0), 0);
        $q      = trim((string)$r->query('q', ''));
        $tab    = strtolower((string)$r->query('tab', 'global')); // global|local|follow
        $lat    = $r->query('lat');
        $lng    = $r->query('lng');
        $radius = (float)$r->query('radius_km', 50); // для tab=local

        // Безопасные выражения под фактическую схему
        $commentsExpr = Schema::hasColumn('catch_comments','is_approved')
            ? '(select count(*) from catch_comments cc where cc.catch_id = cr.id and cc.is_approved = 1)'
            : '(select count(*) from catch_comments cc where cc.catch_id = cr.id)';

        $placeExpr = Schema::hasTable('fishing_points')
            ? "(select fp.title from fishing_points fp where (fp.status = 'approved' or fp.status is null)
                order by POW(fp.lat - cr.lat, 2) + POW(fp.lng - cr.lng, 2) asc limit 1)"
            : "NULL";

        $select = [
            'cr.id','cr.user_id','u.name as user_name',
            DB::raw(Schema::hasColumn('users','photo_url') ? 'u.photo_url as user_avatar' : 'NULL as user_avatar'),
            'cr.lat','cr.lng','cr.species','cr.length','cr.weight','cr.style','cr.lure','cr.tackle','cr.notes',
            'cr.photo_url','cr.caught_at','cr.created_at',
            DB::raw('(select count(*) from catch_likes cl where cl.catch_id = cr.id) as likes_count'),
            DB::raw("$commentsExpr as comments_count"),
            DB::raw("$placeExpr as place_title"),
            DB::raw('0 as liked_by_me')
        ];

        $qbase = DB::table('catch_records as cr')
            ->leftJoin('users as u', 'u.id', '=', 'cr.user_id')
            ->whereIn('cr.privacy', ['all','public','everyone']);

        if ($q !== '') {
            $qbase->where(function($w) use ($q){
                $w->where('cr.species','like',"%{$q}%")
                  ->orWhere('cr.lure','like',"%{$q}%")
                  ->orWhere('cr.tackle','like',"%{$q}%")
                  ->orWhere('cr.notes','like',"%{$q}%")
                  ->orWhere('u.name','like',"%{$q}%");
            });
        }

        if ($tab === 'local' && is_numeric($lat) && is_numeric($lng)) {
            $lat = (float)$lat; $lng = (float)$lng;
            $delta = max($radius, 1.0) / 111.0; // ~1° = 111км
            $minLat = $lat - $delta; $maxLat = $lat + $delta;
            $minLng = $lng - $delta; $maxLng = $lng + $delta;
            $qbase->whereBetween('cr.lat', [$minLat, $maxLat])
                  ->whereBetween('cr.lng', [$minLng, $maxLng]);
        } elseif ($tab === 'follow') {
            // Если авторизации нет — просто не фильтруем дополнительно (или верните пусто по желанию)
            if (auth()->check() && Schema::hasTable('follows')) {
                $uid = auth()->id();
                $qbase->whereIn('cr.user_id', function($sub) use ($uid) {
                    $sub->from('follows')->select('followee_id')->where('follower_id', $uid);
                });
            }
        }

        $items = $qbase->orderByDesc('cr.created_at')->offset($offset)->limit($limit)->get($select);

        return response()->json([
            'items'  => $items,
            'limit'  => $limit,
            'offset' => $offset,
            'next'   => count($items) === $limit ? $offset + $limit : null,
        ]);
    }

    // Публичные комментарии по улову (для отображения списка по клику)
    public function comments($id, Request $r)
    {
        $limit  = min(max((int)$r->query('limit', 20), 1), 100);
        $offset = max((int)$r->query('offset', 0), 0);

        $q = DB::table('catch_comments as c')
            ->leftJoin('users as u','u.id','=','c.user_id')
            ->where('c.catch_id',$id);

        if (Schema::hasColumn('catch_comments','is_approved')) {
            $q->where('c.is_approved', 1);
        }

        $rows = $q->orderBy('c.created_at','asc')
            ->offset($offset)->limit($limit)
            ->get([
                'c.id','c.user_id','u.name as user_name',
                DB::raw(Schema::hasColumn('users','photo_url') ? 'u.photo_url as user_avatar' : 'NULL as user_avatar'),
                'c.body','c.created_at'
            ]);

        return response()->json([
            'items'  => $rows,
            'limit'  => $limit,
            'offset' => $offset,
            'next'   => count($rows)===$limit ? $offset+$limit : null,
        ]);
    }
}
