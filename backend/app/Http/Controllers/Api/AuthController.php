<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class AuthController extends Controller
{
    public function register(Request $r)
    {
        $data = $r->validate([
            'email'    => ['required','email','max:255', Rule::unique('users','email')],
            'password' => ['required','string','min:6','max:72'],
            'name'     => ['required','string','max:255'],
        ]);

        $user = User::create([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => Hash::make($data['password']),
        ]);

        $token = $user->createToken('api')->plainTextToken;
        return response()->json(['token' => $token], 201);
    }

    public function login(Request $r)
    {
        $data = $r->validate([
            'email'    => ['required','email'],
            'password' => ['required','string'],
        ]);

        /** @var User|null $user */
        $user = User::where('email', $data['email'])->first();

        if (!$user || !Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $token = $user->createToken('api')->plainTextToken;
        return response()->json(['token' => $token]);
    }

    public function logout(Request $r)
    {
        $r->user()->currentAccessToken()?->delete();
        return response()->json(['ok' => true]);
    }

    public function me(Request $r)
    {
        $u = $r->user();
        return response()->json([
            'id'    => $u->id,
            'name'  => $u->name,
            'email' => $u->email,
            'avatar'=> $u->avatar_path ? url('/storage/'.$u->avatar_path) : null,
            'handle'=> $u->handle,
            'dob'   => $u->dob,
            'bio'   => $u->bio,
            'links' => $u->links,
            'stats' => [
                'catches' => 0,
                'points'  => 0,
                'likes'   => 0,
            ],
        ]);
    }
}
