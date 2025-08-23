#!/usr/bin/env bash
set -euo pipefail

# === НАСТРОЙКИ ===
APP_DIR="/var/www/fishtrackpro"              # корень проекта с backend/ и frontend/
BRANCH="${BRANCH:-main}"                      # нужная ветка
RUN_MIGRATIONS="${RUN_MIGRATIONS:-0}"         # 1 = запустить миграции, 0 = пропустить
PHP_FPM_SOCK="/run/php/php8.2-fpm.sock"       # путь к php-fpm сокету/сервису
PHP_FPM_SVC="php8.2-fpm"                      # имя systemd сервиса php-fpm
NODE_ENV="${NODE_ENV:-production}"
NPM_CMD="${NPM_CMD:-npm}"                      # можно заменить на pnpm/yarn, если используете

BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# === ПОДГОТОВКА ===
cd "$APP_DIR"

if [ ! -d ".git" ]; then
  log "❌ Здесь нет git-репозитория: $APP_DIR"
  exit 1
fi

# === GIT ОБНОВЛЕНИЕ (reset --hard, чтобы точно применять изменения) ===
log "▶ Git fetch + reset на ветку $BRANCH"
git fetch --all --prune
git checkout "$BRANCH"
git reset --hard "origin/$BRANCH"
git submodule update --init --recursive

# === BACKEND (Laravel) ===
if [ -d "$BACKEND_DIR" ]; then
  log "▶ Backend: composer install (no-dev, оптимизация автолоадера)"
  cd "$BACKEND_DIR"
  if [ ! -f "composer.phar" ] && ! command -v composer >/dev/null 2>&1; then
    log "• composer не найден, ставлю локально"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --quiet
    rm composer-setup.php
  fi
  if command -v composer >/dev/null 2>&1; then
    composer install --no-dev --prefer-dist --optimize-autoloader
  else
    php composer.phar install --no-dev --prefer-dist --optimize-autoloader
  fi

  log "▶ Backend: кеши"
  php artisan config:clear || true
  php artisan cache:clear || true
  php artisan route:clear || true
  php artisan view:clear || true
  php artisan config:cache || true
  php artisan route:cache || true
  php artisan view:cache || true

  if [ "$RUN_MIGRATIONS" = "1" ]; then
    log "▶ Backend: миграции (--force)"
    php artisan migrate --force
  else
    log "▶ Backend: миграции пропущены (RUN_MIGRATIONS=0)"
  fi

  # Права на storage и bootstrap/cache
  log "▶ Backend: права на storage/ и bootstrap/cache"
  mkdir -p storage/logs bootstrap/cache
  chown -R www-data:www-data storage bootstrap/cache
  chmod -R ug+rwX storage bootstrap/cache
fi

# === FRONTEND (Vite/React) ===
if [ -d "$FRONTEND_DIR" ]; then
  log "▶ Frontend: install + build"
  cd "$FRONTEND_DIR"
  $NPM_CMD ci || $NPM_CMD install
  VITE_API_BASE="${VITE_API_BASE:-https://api.fishtrackpro.ru/api}" \
  NODE_ENV="$NODE_ENV" $NPM_CMD run build

  # Опционально: копия сборки в nginx webroot, если он другой
  # WEBROOT="/var/www/fishtrackpro_front" && rsync -a --delete dist/ "$WEBROOT"/
fi

# === RELOAD PHP-FPM и NGINX ===
if systemctl is-active --quiet "$PHP_FPM_SVC"; then
  log "▶ Перезагрузка $PHP_FPM_SVC"
  systemctl reload "$PHP_FPM_SVC" || systemctl restart "$PHP_FPM_SVC"
fi

if systemctl is-active --quiet nginx; then
  log "▶ Перезагрузка nginx"
  systemctl reload nginx || systemctl restart nginx
fi

log "✅ Деплой завершён"