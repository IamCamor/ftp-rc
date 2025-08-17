<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ClubsController extends Controller
{
    public function index() { return response()->json(DB::table('clubs')->orderBy('name')->limit(100)->get()); }

    public function store(Request $r)
    {
        $id = DB::table('clubs')->insertGetId([
            'name'=>$r->string('name','Клуб'),
            'region'=>$r->string('region', null),
            'description'=>$r->string('description', null),
            'logo_url'=>null,
            'members_count'=>0,
            'created_at'=>now(), 'updated_at'=>now()
        ]);
        return response()->json(DB::table('clubs')->where('id',$id)->first(), 201);
    }

    public function logo(Request $r, int $id)
    {
        if (!$r->hasFile('file')) return response()->json(['error'=>'file_required'], 422);
        $path = $r->file('file')->store('public/clubs');
        $url = Storage::url($path);
        DB::table('clubs')->where('id',$id)->update(['logo_url'=>$url, 'updated_at'=>now()]);
        return response()->json(['ok'=>true,'url'=>$url]);
    }
}
