<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PointsController extends Controller
{
    public function index(Request $r)
    {
        $limit = min(1000, (int) $r->query('limit', 500));
        $filter = $r->query('filter'); // spot|shop|slip|camp|null
        $bbox = $r->query('bbox');     // minLng,minLat,maxLng,maxLat

        $q = DB::table('fishing_points')->select('id','title','description','lat','lng','category','is_highlighted','status')
            ->where('is_public', 1)
            ->where('status','approved');

        if ($filter) $q->where('category',$filter);
        if ($bbox) {
            $parts = array_map('floatval', explode(',', $bbox));
            if (count($parts) === 4) {
                [$minLng,$minLat,$maxLng,$maxLat] = $parts;
                $q->whereBetween('lat', [$minLat,$maxLat])
                  ->whereBetween('lng', [$minLng,$maxLng]);
            }
        }
        $items = $q->orderByDesc('id')->limit($limit)->get();
        return response()->json(['items'=>$items]);
    }
}
