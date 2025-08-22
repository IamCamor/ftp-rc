<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;
use Laravel\Socialite\Facades\Socialite;

class OAuthController extends Controller
{
    // GET /auth/{provider}/redirect?return_uri=...
    public function redirect(Request $r, string $provider)
    {
        $returnUri = $r->query('return_uri', url('/'));
        $state = base64_encode(json_encode(['return_uri' => $returnUri]));
        // для сторонних провайдеров выберите правильный driver
        $driver = $this->driverName($provider);
        return Socialite::driver($driver)->stateless()->with(['state' => $state])->redirect();
    }

    // GET /auth/{provider}/callback
    public function callback(Request $r, string $provider)
    {
        $driver = $this->driverName($provider);
        $stateRaw = $r->query('state');
        $state = [];
        if ($stateRaw) {
            $state = json_decode(base64_decode($stateRaw), true) ?: [];
        }
        $returnUri = $state['return_uri'] ?? url('/');

        $oauthUser = Socialite::driver($driver)->stateless()->user();

        $email = $oauthUser->getEmail() ?: "{$provider}_".Str::uuid()."@example.local";
        $name  = $oauthUser->getName() ?: ($oauthUser->getNickname() ?: 'User');

        /** @var User $user */
        $user = User::firstOrCreate(
            ['email' => $email],
            ['name' => $name, 'password' => Hash::make(Str::random(32))]
        );

        $token = $user->createToken('api')->plainTextToken;

        // Требуется ли мастер профиля?
        $needsProfile = empty($user->handle) ? 1 : 0;

        // редирект обратно во фронт:
        $sep = str_contains($returnUri, '?') ? '&' : '?';
        return redirect()->away($returnUri . "{$sep}token={$token}&needs_profile={$needsProfile}");
    }

    private function driverName(string $p): string
    {
        return match ($p) {
            'google' => 'google',
            'vk'     => 'vkontakte',
            'yandex' => 'yandex',
            'apple'  => 'apple',
            default  => abort(404),
        };
    }
}
