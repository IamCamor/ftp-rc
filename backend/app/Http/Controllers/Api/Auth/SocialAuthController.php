<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\User;

class SocialAuthController extends Controller
{
    public function google(Request $r)
    {
        $idToken = $r->string('id_token');
        if (!$idToken) return response()->json(['error'=>'id_token required'], 422);
        $resp = Http::get('https://oauth2.googleapis.com/tokeninfo', ['id_token'=>$idToken]);
        if (!$resp->ok()) return response()->json(['error'=>'invalid_token'], 401);
        $info = $resp->json();
        $email = $info['email'] ?? null;
        $name = $info['name'] ?? ($info['email'] ?? 'User');
        if (!$email) return response()->json(['error'=>'email_required'], 422);
        $user = User::firstOrCreate(['email'=>$email], ['name'=>$name, 'password'=>bcrypt(str()->random(16))]);
        $token = $user->createToken('api')->plainTextToken;
        return response()->json(['token'=>$token, 'user'=>$user]);
    }

    public function apple(Request $r)
    {
        $identity = $r->string('identity_token');
        if (!$identity) return response()->json(['error'=>'identity_token required'], 422);
        $email = $r->string('email', 'apple_user_' . substr(hash('sha256', $identity),0,8) . '@example.com');
        $name = $r->string('name', 'Apple User');
        $user = User::firstOrCreate(['email'=>$email], ['name'=>$name, 'password'=>bcrypt(str()->random(16))]);
        $token = $user->createToken('api')->plainTextToken;
        return response()->json(['token'=>$token, 'user'=>$user]);
    }

    public function telegram(Request $r)
    {
        $data = $r->input('initData');
        if (!is_array($data)) return response()->json(['error'=>'initData array required'], 422);
        $email = "tg_" . ($data['id'] ?? 'user') . "@example.com";
        $user = User::firstOrCreate(['email'=>$email], ['name'=>$data['username'] ?? 'tg_user', 'password'=>bcrypt(str()->random(16))]);
        $token = $user->createToken('api')->plainTextToken;
        return response()->json(['token'=>$token, 'user'=>$user]);
    }
}
