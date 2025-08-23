<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CommentController extends Controller
{
    public function store(Request $r, $id)
    {
        $r->validate(['body'=>'required|string|min:1']);
        $userId = $r->user()->id ?? $r->input('user_id'); // временно допускаем user_id в теле
        if(!$userId) return response()->json(['message'=>'Unauthorized'],401);

        $cid = DB::table('catch_comments')->insertGetId([
            'catch_id'=>(int)$id, 'user_id'=>(int)$userId, 'body'=>$r->input('body'),
            'is_approved'=>1, 'created_at'=>now(), 'updated_at'=>now()
        ]);
        return response()->json(['ok'=>true,'comment_id'=>$cid]);
    }
}
