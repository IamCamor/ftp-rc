<?php
namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\DB;

class UserCatchesController extends Controller
{
    public function index($id, Request $r)
    {
        $limit = (int)$r->query('limit', 20);
        $offset = (int)$r->query('offset', 0);

        $rows = DB::table('catch_records as cr')
            ->leftJoin('users as u','u.id','=','cr.user_id')
            ->leftJoin('fishing_points as p','p.id','=','cr.point_id')
            ->selectRaw('cr.id, cr.user_id, u.name as user_name, u.avatar_url as user_avatar_url,
                cr.lat, cr.lng, cr.species, cr.length as size_cm, cr.weight as weight_g,
                cr.style as method, cr.tackle as gear, cr.lure as bait, cr.notes as caption,
                cr.photo_url as media_url, cr.created_at,
                p.id as point_id, p.title as point_title,
                (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id = cr.id) as likes_count,
                (SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id = cr.id) as comments_count')
            ->where('cr.user_id', $id)
            ->where('cr.privacy','!=','private')
            ->orderByDesc('cr.created_at')
            ->limit($limit)->offset($offset)->get();

        return response()->json(['items'=>$rows]);
    }

    public function markers($id, Request $r)
    {
        $limit = (int)$r->query('limit', 500);
        $rows = DB::table('catch_records as cr')
            ->selectRaw('cr.id, cr.lat, cr.lng, cr.species, cr.created_at')
            ->where('cr.user_id', $id)
            ->where('cr.privacy','!=','private')
            ->orderByDesc('cr.created_at')
            ->limit($limit)->get();
        return response()->json(['items'=>$rows]);
    }
}
