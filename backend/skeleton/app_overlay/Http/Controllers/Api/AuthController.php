<?php
namespace App\Http\Controllers\Api; use Illuminate\Http\Request; use Illuminate\Support\Facades\Hash; use App\Models\User; use Illuminate\Routing\Controller as BaseController;
class AuthController extends BaseController {
  public function register(Request $r){ $d=$r->validate(['name'=>'required','email'=>'required|email|unique:users','password'=>'required|min:6']);
    $u=User::create(['name'=>$d['name'],'email'=>$d['email'],'password'=>Hash::make($d['password'])]); $t=$u->createToken('api')->plainTextToken; return response()->json(['token'=>$t],201); }
  public function login(Request $r){ $d=$r->validate(['email'=>'required|email','password'=>'required']); $u=User::where('email',$d['email'])->first();
    if(!$u || !password_verify($d['password'],$u->password)) return response()->json(['message'=>'Invalid credentials'],401);
    return response()->json(['token'=>$u->createToken('api')->plainTextToken]); }
  public function me(Request $r){ return response()->json($r->user()); }
}