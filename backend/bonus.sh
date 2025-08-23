#!/usr/bin/env bash
set -euo pipefail

ts() { date +"%Y%m%d_%H%M%S"; }
info(){ echo -e "➡️  $*"; }
ok(){ echo -e "✅ $*"; }
err(){ echo -e "❌ $*" >&2; }

ROUTES_FILE="routes/api.php"
LISTENER_FILE="app/Listeners/AwardBonusOnRegister.php"

[[ -f "$ROUTES_FILE" ]] || { err "Не найден $ROUTES_FILE"; exit 1; }

# 1) Создаём listener при отсутствии
if [[ ! -f "$LISTENER_FILE" ]]; then
  info "Создаю $LISTENER_FILE"
  mkdir -p "$(dirname "$LISTENER_FILE")"
  cat > "$LISTENER_FILE" <<'PHP'
<?php

namespace App\Listeners;

use App\Services\BonusService;
use Illuminate\Auth\Events\Registered;

class AwardBonusOnRegister
{
    public function __construct(private readonly BonusService $bonusService) {}

    public function handle(Registered $event): void
    {
      $user = $event->user;
      try {
          $this->bonusService->earn($user, 'register');
      } catch (\Throwable $e) {
          logger()->warning('Bonus earn failed on register', [
              'user_id' => $user->id ?? null,
              'error' => $e->getMessage(),
          ]);
      }
    }
}
PHP
  ok "Listener создан"
else
  ok "Listener уже существует — пропускаю"
fi

# 2) Патчим routes/api.php
backup_routes="${ROUTES_FILE}.bak.$(ts)"
cp "$ROUTES_FILE" "$backup_routes"
info "Бэкап routes: $backup_routes"

# Добавим use для контроллера, если нет
if ! grep -qE 'use\s+App\\Http\\Controllers\\Api\\BonusController;' "$ROUTES_FILE"; then
  info "Добавляю use BonusController в $ROUTES_FILE"
  if grep -qE 'use\s+Illuminate\\Support\\Facades\\Route;' "$ROUTES_FILE"; then
    sed -i '' -e '/use\s\+Illuminate\\Support\\Facades\\Route;/a\
use App\\Http\\Controllers\\Api\\BonusController;
' "$ROUTES_FILE" 2>/dev/null || sed -i -e '/use\s\+Illuminate\\Support\\Facades\\Route;/a use App\\Http\\Controllers\\Api\\BonusController;' "$ROUTES_FILE"
  else
    sed -i '' -e "1i\\
use App\\Http\\Controllers\\Api\\BonusController;
" "$ROUTES_FILE" 2>/dev/null || sed -i -e '1i use App\\Http\\Controllers\\Api\\BonusController;' "$ROUTES_FILE"
  fi
else
  ok "use BonusController уже есть"
fi

# Добавим блок маршрутов, если его нет
if ! grep -q "/bonus/me" "$ROUTES_FILE"; then
  info "Добавляю блок маршрутов /bonus/* в $ROUTES_FILE"
  cat >> "$ROUTES_FILE" <<'PHP'

/* === Bonus System Routes (auto-insert) === */
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/bonus/me', [BonusController::class, 'me']);
    Route::get('/bonus/history', [BonusController::class, 'history']);
    Route::post('/bonus/redeem-pro', [BonusController::class, 'redeemPro']);
});
/* === /Bonus System Routes === */

PHP
  ok "Роуты добавлены"
else
  ok "Роуты /bonus уже существуют — пропускаю"
fi

ok "Готово! Проверь изменения и выполни:"
echo "   php artisan config:clear"
echo "   php artisan optimize:clear"
echo "   php artisan migrate"
