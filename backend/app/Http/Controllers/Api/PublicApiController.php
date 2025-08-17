<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class PublicApiController extends Controller
{
    public function user(string $slug)
    {
        $user = DB::table('users')->where('slug', $slug)->first();
        if (!$user && is_numeric($slug)) { $user = DB::table('users')->where('id', (int)$slug)->first(); }
        if (!$user) return response()->json(['error'=>'not_found'], 404);
        $catches = DB::table('catch_records')->where('user_id', $user->id)->orderByDesc('id')->limit(20)->get();
        return response()->json([
            'user'=>[ 'id'=>$user->id,'name'=>$user->name,'slug'=>$user->slug ?: (string)$user->id,'avatar_url'=>$user->avatar_url ?? null,'bio'=>$user->bio ?? null ],
            'catches'=>$catches,
        ]);
    }
    public function catch(int $id)
    {
        $c = DB::table('catch_records')->where('id', $id)->first();
        if (!$c) return response()->json(['error'=>'not_found'], 404);
        $author = DB::table('users')->select('id','name','slug')->where('id', $c->user_id)->first();
        return response()->json([ 'id'=>$c->id,'species'=>$c->species,'weight'=>$c->weight,'length'=>$c->length,'depth'=>$c->depth,'style'=>$c->style,'lure'=>$c->lure,'photo_url'=>$c->photo_url ?? null,'author'=>$author ]);
    }
}
