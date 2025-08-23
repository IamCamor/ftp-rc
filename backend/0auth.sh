#!/bin/bash
set -e

BASE_DIR="/var/www/fishtrackpro/backend/app"

echo "=== Создаём/обновляем контроллер OAuthController.php ==="
mkdir -p "$BASE_DIR/Http/Controllers/Web"
cat > "$BASE_DIR/Http/Controllers/Web/OAuthController.php" <<'PHP'
<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;
use Laravel\Socialite\Facades\Socialite;
use Laravel\Socialite\Two\AbstractProvider;

class OAuthController extends Controller
{
    public function redirect(Request $r, string $provider)
    {
        $returnUri = $r->query('return_uri', url('/'));
        $state = base64_encode(json_encode(['return_uri' => $returnUri]));
        $driver = $this->driverName($provider);

        return Socialite::driver($driver)->with(['state' => $state])->redirect();
    }

    public function callback(Request $r, string $provider)
    {
        $driver = $this->driverName($provider);

        $stateRaw = (string) $r->query('state', '');
        $state = [];
        if ($stateRaw !== '') {
            $decoded = base64_decode($stateRaw, true);
            if (is_string($decoded)) {
                $state = json_decode($decoded, true) ?: [];
            }
        }
        $returnUri = $state['return_uri'] ?? url('/');

        /** @var AbstractProvider $prov */
        $prov = Socialite::driver($driver);
        $oauthUser = $prov->stateless()->user();

        $email = $oauthUser->getEmail() ?: "{$provider}_".Str::uuid()."@example.local";
        $name  = $oauthUser->getName() ?: ($oauthUser->getNickname() ?: 'User');

        $user = User::firstOrCreate(
            ['email' => $email],
            ['name' => $name, 'password' => Hash::make(Str::random(32))]
        );

        $token = $user->createToken('api')->plainTextToken;
        $needsProfile = empty($user->handle) ? 1 : 0;

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
PHP

echo "=== Создаём/обновляем middleware ==="
mkdir -p "$BASE_DIR/Http/Middleware"

# TrustProxies
cat > "$BASE_DIR/Http/Middleware/TrustProxies.php" <<'PHP'
<?php

namespace App\Http\Middleware;

use Illuminate\Http\Middleware\TrustProxies as Middleware;
use Illuminate\Http\Request;

class TrustProxies extends Middleware
{
    protected $proxies;
    protected $headers = Request::HEADER_X_FORWARDED_ALL;
}
PHP

# PreventRequestsDuringMaintenance
cat > "$BASE_DIR/Http/Middleware/PreventRequestsDuringMaintenance.php" <<'PHP'
<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\PreventRequestsDuringMaintenance as Middleware;

class PreventRequestsDuringMaintenance extends Middleware
{
    protected $except = [];
}
PHP

# TrimStrings
cat > "$BASE_DIR/Http/Middleware/TrimStrings.php" <<'PHP'
<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\TrimStrings as Middleware;

class TrimStrings extends Middleware
{
    protected $except = [
        'current_password',
        'password',
        'password_confirmation',
    ];
}
PHP

# EncryptCookies
cat > "$BASE_DIR/Http/Middleware/EncryptCookies.php" <<'PHP'
<?php

namespace App\Http\Middleware;

use Illuminate\Cookie\Middleware\EncryptCookies as Middleware;

class EncryptCookies extends Middleware
{
    protected $except = [];
}
PHP

# VerifyCsrfToken
cat > "$BASE_DIR/Http/Middleware/VerifyCsrfToken.php" <<'PHP'
<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

class VerifyCsrfToken extends Middleware
{
    protected $addHttpCookie = true;

    protected $except = [
        // добавить пути для исключения при необходимости
    ];
}
PHP

# Authenticate
cat > "$BASE_DIR/Http/Middleware/Authenticate.php" <<'PHP'
<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;

class Authenticate extends Middleware
{
    protected function redirectTo($request): ?string
    {
        if (!$request->expectsJson()) {
            return route('login');
        }
        return null;
    }
}
PHP

# RedirectIfAuthenticated
cat > "$BASE_DIR/Http/Middleware/RedirectIfAuthenticated.php" <<'PHP'
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RedirectIfAuthenticated
{
    public function handle(Request $request, Closure $next, ...$guards)
    {
        $guards = $guards ?: [null];
        foreach ($guards as $guard) {
            if (Auth::guard($guard)->check()) {
                return redirect('/');
            }
        }
        return $next($request);
    }
}
PHP

echo "=== Очистка кэшей Laravel ==="
cd /var/www/fishtrackpro/backend
php artisan optimize:clear || true

echo "=== Готово! ==="
