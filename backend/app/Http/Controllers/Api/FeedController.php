<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FeedController extends Controller
{
    public function index(Request $r)
    {
        $tab = $r->string('tab','global');
        $items = DB::table('catch_records')->orderByDesc('id')->limit(100)->get();
        return response()->json(['tab'=>$tab,'items'=>$items]);
    }
}
