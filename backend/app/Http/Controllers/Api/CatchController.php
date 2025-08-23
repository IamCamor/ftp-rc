<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CatchController extends Controller
{
    public function show($id)
    {
        $row = DB::table('catch_records AS cr')
            ->leftJoin('users AS u','u.id','=','cr.user_id')
            ->selectRaw("
                cr.*, u.name AS user_name,
                COALESCE(u.avatar, u.photo_url, '') AS user_avatar,
                (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count,
                (SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id=cr.id AND (cc.is_approved=1 OR cc.is_approved IS NULL)) AS comments_count
            ")
            ->where('cr.id',(int)$id)->first();
        if(!$row) return response()->json(['message'=>'Not found'],404);

        $comments = DB::table('catch_comments AS c')
            ->leftJoin('users AS u','u.id','=','c.user_id')
            ->selectRaw("c.id,c.body,c.created_at, COALESCE(u.name,'Гость') AS user_name, COALESCE(u.avatar,u.photo_url,'') AS user_avatar")
            ->where('c.catch_id',(int)$id)
            ->where(function($w){ $w->where('c.is_approved',1)->orWhereNull('c.is_approved'); })
            ->orderBy('c.created_at','asc')->limit(100)->get();

        return response()->json(['item'=>$row,'comments'=>$comments]);
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'lat'=>'required|numeric','lng'=>'required|numeric',
            'species'=>'nullable|string','length'=>'nullable|numeric','weight'=>'nullable|numeric',
            'style'=>'nullable|string','lure'=>'nullable|string','tackle'=>'nullable|string',
            'notes'=>'nullable|string','photo_url'=>'nullable|string',
            'caught_at'=>'nullable|date','privacy'=>'nullable|in:all,friends,private',
            'water_type'=>'nullable|string','water_temp'=>'nullable|numeric','wind_speed'=>'nullable|numeric','pressure'=>'nullable|numeric'
        ]);
        $data['privacy'] = $data['privacy'] ?? 'all';
        $id = DB::table('catch_records')->insertGetId($data);
        return $this->show($id);
    }

    public function markers(Request $r)
    {
        $species = $r->query('species');
        $q = DB::table('catch_records')->select('id','lat','lng','species')->where('privacy','all');
        if($species) $q->where('species','like','%'.$species.'%');
        return response()->json(['items'=>$q->orderByDesc('id')->limit(1000)->get()]);
    }
}
