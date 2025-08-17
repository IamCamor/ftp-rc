# S11: Карта (Leaflet), формы событий/клубов, админка (модерация и роли), e-mail шаблоны, Stripe/YooKassa webhooks

## Установка фронта (добавления)
- Установи зависимости карты:
```bash
cd frontend
npm i leaflet react-leaflet
```
- Подключи экран карты в `src/ui/App.tsx` (у тебя уже есть `/map`). Файл экрана: `src/ui/screens/MapScreen.tsx`.
- Формы: `src/ui/components/forms/EventForm.tsx`, `ClubForm.tsx` (подключи в нужные экраны).
- Админка SPA: `src/ui/screens/AdminScreen.tsx` (добавь роут `/admin` в App.tsx, кнопка в AppBar по желанию).

## Бэкенд
1) Добавь в `routes/api.php`:
```php
require base_path('routes/api_admin.php');
```
2) Миграции:
```bash
php artisan migrate
```
3) Сидеры (включая админа):
```bash
php artisan db:seed --class=Database\Seeders\AdminSeeder
```
Админ: `admin@fishtrackpro.local` / `admin123`

4) Почта
В `.env`:
```
MAIL_MAILER=log
MAIL_FROM_ADDRESS=no-reply@fishtrackpro.ru
MAIL_FROM_NAME="FishTrackPro"
```
Логи писем смотреть в `storage/logs/laravel.log`.

5) Stripe / YooKassa
В `.env`:
```
STRIPE_SECRET=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
YOOKASSA_SHOP_ID=xxx
YOOKASSA_SECRET=xxx
```
Включи вебхуки провайдеров на адреса:
- Stripe: `POST /api/webhooks/stripe`
- YooKassa: `POST /api/webhooks/yookassa`

## Маршруты админки (API)
- `GET /api/admin/comments/pending` — список ожидающих
- `POST /api/admin/comments/{id}/approve|reject`
- `GET /api/admin/points/pending` — точки на модерации
- `POST /api/admin/points/{id}/approve|reject`
- `GET /api/admin/users` — пользователи и роли
- `POST /api/admin/users/{id}/role` — назначить роль

## Примечания
- В MapView используется OSM через Leaflet (токен не требуется).
- Маркеры подгружаются из `/api/map/points`, фильтр по категории.
- Добавление точки — кнопка FAB, берём геолокацию пользователя.
- Email шаблоны в `resources/views/emails/`, Mailable в `app/Mail/*`.
- Реальные платежи: контроллеры создают checkout-сессию и принимают вебхуки; выстави ключи в `.env`.
