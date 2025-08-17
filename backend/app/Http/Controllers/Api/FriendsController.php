<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Friendship;

class FriendsController extends Controller {
  public function index(){
    $uid = auth()->id();
    return Friendship::where(function($q) use ($uid){
      $q->where('user_id',$uid)->orWhere('friend_id',$uid);
    })->get();
  }
  public function request(Request $r){
    $uid = auth()->id();
    $data = $r->validate(['friend_id'=>'required|integer']);
    $f = Friendship::firstOrCreate(['user_id'=>$uid,'friend_id'=>$data['friend_id']], ['status'=>'pending']);
    return $f;
  }
  public function accept($id){
    $uid = auth()->id();
    $f = Friendship::findOrFail($id);
    if ($f->friend_id != $uid) abort(403);
    $f->status='accepted'; $f->save();
    return $f;
  }
  public function decline($id){
    $uid = auth()->id();
    $f = Friendship::findOrFail($id);
    if ($f->friend_id != $uid) abort(403);
    $f->status='declined'; $f->save();
    return $f;
  }
}