#!/usr/bin/env sh
set -e
if [ ! -f artisan ]; then
  echo "Bootstrapping Laravel..."
  composer create-project laravel/laravel . --no-interaction
  php artisan key:generate
  composer require laravel/sanctum tymon/jwt-auth:^2.0 predis/predis:^2.0 --no-interaction
  php artisan vendor:publish --provider="Tymon\\JWTAuth\\Providers\\LaravelServiceProvider" || true
fi
cp -rT app_overlay app 2>/dev/null || true
cp -rT routes_overlay routes 2>/dev/null || true
cp -rT config_overlay config 2>/dev/null || true
cp -rT database_overlay database 2>/dev/null || true
cp -rT tests_overlay tests 2>/dev/null || true
php artisan migrate --force || true
php artisan db:seed --force || true
echo "Laravel is ready."
