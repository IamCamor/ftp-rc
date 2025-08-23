<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FollowController extends Controller
{
    public function toggle(Request $r, $targetId)
    {
        $userId = $r->user()->id ?? $r->input('user_id');
        if(!$userId) return response()->json(['message'=>'Unauthorized'],401);
        if((int)$userId === (int)$targetId) return response()->json(['message'=>'Bad request'],400);

        $ex = DB::table('follows')->where(['follower_id'=>(int)$userId,'followed_id'=>(int)$targetId])->first();
        if($ex){
            DB::table('follows')->where('id',$ex->id)->delete();
            $following=false;
        }else{
            DB::table('follows')->insert(['follower_id'=>(int)$userId,'followed_id'=>(int)$targetId,'created_at'=>now(),'updated_at'=>now()]);
            $following=true;
        }
        return response()->json(['ok'=>true,'following'=>$following]);
    }
}
