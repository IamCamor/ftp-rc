<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class EventsController extends Controller
{
    public function index() { return response()->json(DB::table('events')->orderByDesc('starts_at')->limit(100)->get()); }

    public function store(Request $r)
    {
        $id = DB::table('events')->insertGetId([
            'title'=>$r->string('title','Событие'),
            'region'=>$r->string('region', null),
            'starts_at'=>$r->string('starts_at', null),
            'ends_at'=>$r->string('ends_at', null),
            'description'=>$r->string('description', null),
            'location_lat'=>$r->float('location_lat', null),
            'location_lng'=>$r->float('location_lng', null),
            'link'=>$r->string('link', null),
            'org_club_id'=>null,
            'created_at'=>now(), 'updated_at'=>now(),
        ]);
        return response()->json(DB::table('events')->where('id',$id)->first(), 201);
    }

    public function photo(Request $r, int $id)
    {
        if (!$r->hasFile('file')) return response()->json(['error'=>'file_required'], 422);
        $path = $r->file('file')->store('public/events');
        $url = Storage::url($path);
        DB::table('events')->where('id',$id)->update(['photo_url'=>$url, 'updated_at'=>now()]);
        return response()->json(['ok'=>true,'url'=>$url]);
    }
}
