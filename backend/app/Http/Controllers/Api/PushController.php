<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PushController extends Controller
{
    public function register(Request $r)
    {
        $r->validate([ 'platform'=>'required|string|in:web,ios,android', 'token'=>'required|string' ]);
        DB::table('push_subscriptions')->updateOrInsert(
            ['user_id'=>1, 'platform'=>$r->string('platform'), 'token'=>$r->string('token')],
            ['last_seen_at'=>now(), 'updated_at'=>now(), 'created_at'=>now()]
        );
        return response()->json(['ok'=>true]);
    }
    public function test() { return response()->json(['ok'=>true,'note'=>'demo']); }
}
