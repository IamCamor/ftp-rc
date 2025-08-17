<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class AdminCommentsController extends Controller
{
    public function pending()
    {
        return response()->json(DB::table('catch_comments')->where('is_approved', false)->orderByDesc('id')->limit(200)->get());
    }
    public function approve(int $id){ DB::table('catch_comments')->where('id',$id)->update(['is_approved'=>true]); return response()->json(['ok'=>true]); }
    public function reject(int $id){ DB::table('catch_comments')->where('id',$id)->delete(); return response()->json(['ok'=>true]); }
}
