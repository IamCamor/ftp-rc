<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PointsController extends Controller
{
    public function index(Request $r)
    {
        $limit = min(1000,(int)$r->query('limit',500));
        $filter = $r->query('filter'); // spot|shop|slip|camp
        $bbox = $r->query('bbox');     // minLng,minLat,maxLng,maxLat

        $q = DB::table('fishing_points')
            ->select('id','title','description','lat','lng','category','is_highlighted','status')
            ->where('is_public',1)->where('status','approved');

        if($filter) $q->where('category',$filter);
        if($bbox){
            $p = array_map('floatval', explode(',',$bbox));
            if(count($p)===4){ [$minLng,$minLat,$maxLng,$maxLat]=$p;
                $q->whereBetween('lat',[$minLat,$maxLat])->whereBetween('lng',[$minLng,$maxLng]);
            }
        }
        return response()->json(['items'=>$q->orderByDesc('id')->limit($limit)->get()]);
    }

    public function categories()
    {
        return response()->json(['items'=>['spot','shop','slip','camp']]);
    }

    public function store(Request $r)
    {
        // пишем только существующие поля
        $data = $r->validate([
            'title'=>'required|string|min:2',
            'description'=>'nullable|string',
            'category'=>'required|in:spot,shop,slip,camp',
            'lat'=>'required|numeric',
            'lng'=>'required|numeric',
            'is_public'=>'boolean',
            'is_highlighted'=>'boolean',
            'status'=>'nullable|in:approved,pending,rejected'
        ]);
        $data['is_public'] = (int)($data['is_public'] ?? 1);
        $data['is_highlighted'] = (int)($data['is_highlighted'] ?? 0);
        $data['status'] = $data['status'] ?? 'approved';
        $id = DB::table('fishing_points')->insertGetId($data);
        $row = DB::table('fishing_points')->where('id',$id)->first();
        return response()->json($row,201);
    }
}
