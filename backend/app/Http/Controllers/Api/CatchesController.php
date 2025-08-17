<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class CatchesController extends Controller
{
    public function index(Request $r)
    {
        $q = DB::table('catch_records')->orderByDesc('id');
        if ($r->filled('species')) $q->where('species', $r->string('species'));
        $items = $q->limit(200)->get();
        return response()->json($items);
    }

    public function store(Request $r)
    {
        $id = DB::table('catch_records')->insertGetId([
            'user_id'=>1,
            'lat'=>$r->float('lat', 55.75),
            'lng'=>$r->float('lng', 37.62),
            'species'=>$r->string('species','Щука'),
            'length'=>$r->float('length', null),
            'weight'=>$r->float('weight', null),
            'depth'=>$r->float('depth', null),
            'style'=>$r->string('style', null),
            'lure'=>$r->string('lure', null),
            'tackle'=>$r->string('tackle', null),
            'privacy'=>$r->string('privacy', 'all'),
            'caught_at'=>$r->string('caught_at', null),
            'water_type'=>$r->string('water_type', null),
            'water_temp'=>$r->float('water_temp', null),
            'wind_speed'=>$r->float('wind_speed', null),
            'pressure'=>$r->float('pressure', null),
            'companions'=>$r->string('companions', null),
            'notes'=>$r->string('notes', null),
            'created_at'=>now(), 'updated_at'=>now(),
        ]);
        return response()->json(DB::table('catch_records')->where('id',$id)->first(), 201);
    }

    public function uploadMedia(Request $r, int $id)
    {
        if (!$r->hasFile('file')) return response()->json(['error'=>'file_required'], 422);
        $path = $r->file('file')->store('public/catches');
        $url = Storage::url($path);
        DB::table('catch_records')->where('id',$id)->update(['photo_url'=>$url, 'updated_at'=>now()]);
        return response()->json(['ok'=>true,'url'=>$url]);
    }

    public function like(Request $r, int $id)
    {
        $exists = DB::table('catch_likes')->where('catch_id',$id)->where('user_id',1)->exists();
        if ($exists) { DB::table('catch_likes')->where('catch_id',$id)->where('user_id',1)->delete(); return response()->json(['liked'=>false]); }
        DB::table('catch_likes')->insert(['catch_id'=>$id,'user_id'=>1,'created_at'=>now()]);
        return response()->json(['liked'=>true]);
    }

    public function comment(Request $r, int $id)
    {
        $r->validate(['body'=>'required|string|max:2000']);
        $cid = DB::table('catch_comments')->insertGetId([
            'catch_id'=>$id, 'user_id'=>1, 'body'=>$r->string('body'),
            'is_approved'=>true, 'created_at'=>now(), 'updated_at'=>now(),
        ]);
        return response()->json(DB::table('catch_comments')->where('id',$cid)->first(), 201);
    }
}
