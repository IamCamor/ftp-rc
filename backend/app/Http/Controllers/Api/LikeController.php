<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LikeController extends Controller
{
    public function toggle(Request $r, $id)
    {
        $userId = $r->user()->id ?? $r->input('user_id');
        if(!$userId) return response()->json(['message'=>'Unauthorized'],401);

        $exists = DB::table('catch_likes')->where(['catch_id'=>(int)$id,'user_id'=>(int)$userId])->first();
        if($exists){
            DB::table('catch_likes')->where('id',$exists->id)->delete();
            $liked=false;
        }else{
            DB::table('catch_likes')->insert(['catch_id'=>(int)$id,'user_id'=>(int)$userId,'created_at'=>now(),'updated_at'=>now()]);
            $liked=true;
        }
        $cnt = DB::table('catch_likes')->where('catch_id',(int)$id)->count();
        return response()->json(['ok'=>true,'liked'=>$liked,'likes_count'=>$cnt]);
    }
}
