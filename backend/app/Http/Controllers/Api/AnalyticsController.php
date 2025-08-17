<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    public function store(Request $r)
    {
        $id = DB::table('analytics_events')->insertGetId([
            'name'=>$r->string('name','event'),
            'user_id'=>1,
            'payload'=>json_encode($r->input('params', []), JSON_UNESCAPED_UNICODE),
            'ip'=>$r->ip(), 'ua'=>$r->userAgent(),
            'created_at'=>now(),'updated_at'=>now()
        ]);
        return response()->json(['ok'=>true,'id'=>$id]);
    }
}
