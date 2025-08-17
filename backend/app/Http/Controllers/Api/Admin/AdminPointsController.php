<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class AdminPointsController extends Controller
{
    public function pending()
    {
        return response()->json(DB::table('fishing_points')->where('status','pending')->orderByDesc('id')->limit(200)->get());
    }
    public function approve(int $id){ DB::table('fishing_points')->where('id',$id)->update(['status'=>'approved']); return response()->json(['ok'=>true]); }
    public function reject(int $id){ DB::table('fishing_points')->where('id',$id)->delete(); return response()->json(['ok'=>true]); }
}
