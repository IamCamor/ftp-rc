# FishTrackPro Backend (S7–S10)

## Быстрый старт (Mac M1)
```bash
cd backend
cp .env.example .env
# Укажи DB_CONNECTION=sqlite и раскомментируй DB_DATABASE
touch database/database.sqlite

composer install
php artisan key:generate

php artisan migrate --force
php artisan db:seed --force

php artisan serve # http://127.0.0.1:8000
```

## Полезные URL
- `/api/map/points` — точки карты
- `/api/catches` — список уловов (POST для создания)
- `/api/events`, `/api/clubs`, `/api/chats`, `/api/notifications`
- `/api/weather?lat=55.75&lng=37.62&units=metric&lang=ru`
- `/api/public/users/{slug}` и `/api/public/catches/{id}`
- `/api/plans`, `/api/create-checkout`, `/api/subscription`

## Cron (Scheduler)
```bash
php artisan schedule:work
```
Команды: `ftp:digest`, `ftp:recalc-ratings`, `ftp:renew-subs`.
