<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FeedController extends Controller
{
    public function index(Request $r)
    {
        $limit = min(50,(int)$r->query('limit',20));
        $offset = max(0,(int)$r->query('offset',0));
        $species = $r->query('species');
        $userId  = $r->query('user_id');
        $placeId = $r->query('place_id');

        $q = DB::table('catch_records AS cr')
            ->leftJoin('users AS u','u.id','=','cr.user_id')
            ->selectRaw("
                cr.id, cr.user_id,
                COALESCE(u.name,'Рыбак') AS user_name,
                '' AS user_avatar,
                cr.lat, cr.lng, cr.species, cr.length, cr.weight,
                cr.style, cr.lure, cr.tackle, cr.notes, cr.photo_url,
                COALESCE(cr.caught_at, cr.created_at) AS created_at,
                (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count,
                (SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id=cr.id) AS comments_count
            ")
            ->where('cr.privacy','all');

        if($species) $q->where('cr.species','like','%'.$species.'%');
        if($userId)  $q->where('cr.user_id',(int)$userId);

        if($placeId){
            $p = DB::table('fishing_points')->where('id',(int)$placeId)->first();
            if($p){
                $lat0=$p->lat; $lng0=$p->lng; $km=2.0;
                $q->whereRaw(
                  "(6371*ACOS( COS(RADIANS(?))*COS(RADIANS(cr.lat))*COS(RADIANS(cr.lng)-RADIANS(?)) + SIN(RADIANS(?))*SIN(RADIANS(cr.lat)) )) <= ?",
                  [$lat0,$lng0,$lat0,$km]
                );
            }
        }

        $items = $q->orderByDesc('created_at')->orderByDesc('cr.id')
                   ->limit($limit)->offset($offset)->get();

        return response()->json([
            'items'=>$items,
            'next_offset'=>$offset + $items->count()
        ]);
    }
}
