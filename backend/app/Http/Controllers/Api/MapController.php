<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class MapController extends Controller
{
    public function index(Request $r)
    {
        $q = DB::table('fishing_points')->where('status','approved')->orderByDesc('is_highlighted')->orderByDesc('id');
        if ($r->filled('category')) $q->where('category', $r->string('category'));
        if ($r->filled('public')) $q->where('is_public', (bool)$r->boolean('public', true));
        $items = $q->limit(1000)->get();
        return response()->json($items);
    }

    public function store(Request $r)
    {
        $r->validate([ 'lat'=>'required|numeric', 'lng'=>'required|numeric', 'title'=>'required|string|max:120', 'category'=>'required|string' ]);
        $id = DB::table('fishing_points')->insertGetId([
            'user_id' => 1,
            'lat'=>$r->float('lat'), 'lng'=>$r->float('lng'),
            'title'=>$r->string('title'), 'description'=>$r->string('description', ''),
            'category'=>$r->string('category'), 'is_public'=>$r->boolean('is_public', true),
            'is_highlighted'=>false, 'status'=>'pending', 'created_at'=>now(), 'updated_at'=>now(),
        ]);
        return response()->json(DB::table('fishing_points')->where('id',$id)->first(), 201);
    }

    public function photo(Request $r, int $id)
    {
        if (!$r->hasFile('file')) return response()->json(['error'=>'file_required'], 422);
        $path = $r->file('file')->store('public/points');
        $url = Storage::url($path);
        DB::table('fishing_points')->where('id',$id)->update(['photo_url'=>$url, 'updated_at'=>now()]);
        return response()->json(['ok'=>true,'url'=>$url]);
    }
}
