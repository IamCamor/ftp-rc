<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChatsController extends Controller
{
    public function index()
    {
        $chats = DB::table('chats')->orderByDesc('id')->limit(20)->get();
        return response()->json($chats);
    }

    public function send(Request $r, int $id)
    {
        $r->validate(['body'=>'required|string|max:2000']);
        $mid = DB::table('chat_messages')->insertGetId(['chat_id'=>$id, 'user_id'=>1, 'body'=>$r->string('body'), 'is_approved'=>true, 'created_at'=>now(), 'updated_at'=>now()]);
        return response()->json(DB::table('chat_messages')->where('id',$mid)->first(), 201);
    }
}
