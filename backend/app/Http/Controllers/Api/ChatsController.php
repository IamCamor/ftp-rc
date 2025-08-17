<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\ChatRoom;
use App\Models\ChatRoomUser;
use App\Models\ChatMessage;

class ChatsController extends Controller {
  public function rooms(){
    $uid = auth()->id();
    $roomIds = ChatRoomUser::where('user_id',$uid)->pluck('room_id');
    return ChatRoom::whereIn('id',$roomIds)->latest()->get();
  }
  public function messages($roomId){
    $uid = auth()->id();
    $exists = ChatRoomUser::where(['room_id'=>$roomId,'user_id'=>$uid])->exists();
    if (!$exists) abort(403);
    return ChatMessage::where('room_id',$roomId)->orderBy('created_at','asc')->limit(200)->get();
  }
  public function send(Request $r, $roomId){
    $uid = auth()->id();
    $exists = ChatRoomUser::where(['room_id'=>$roomId,'user_id'=>$uid])->exists();
    if (!$exists) abort(403);
    $data = $r->validate(['text'=>'required|string|min:1|max:2000']);
    $msg = ChatMessage::create(['room_id'=>$roomId,'user_id'=>$uid,'text'=>$data['text']]);
    return response()->json($msg,201);
  }
}