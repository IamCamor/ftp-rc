FishTrack Pro — PROD Drop V4
==============================

Дата сборки: 2025-09-03T12:37:36.319308Z

Что внутри
----------
1) **backend/**
   - `config/app_ui.php` — конфиг ассетов и фич-флагов (AI модерация, провайдеры).
   - `app/Services/AIModeration.php` — сервис модерации комментариев (OpenAI/Yandex, graceful fallback).
   - Контроллеры:
     - `Api/CommentController.php` — сохранение комментов с AI-модерацией (не валится при ошибке провайдера).
     - `Api/RatingController.php` — рейтинги (week/month/all).
     - `Api/FriendsController.php` — друзья: mutual/following/followers + рекомендации.
     - `Api/UploadController.php` — множественная загрузка файлов.
     - `Api/WeatherProxyController.php` — прокси к OpenWeather с мягкими ошибками.
   - `docs/routes_snippet.txt` — только новые строки для вашего `routes/api.php` (без полного перезаписывания).

2) **frontend/**
   - `src/config/assets.ts` — все картинки (логотип, аватар по умолчанию, паттерн) вынесены в конфиг.
   - Страницы:
     - `screens/RankingsPage.tsx` — рейтинги с табами.
     - `screens/FriendsPage.tsx` — друзья/подписки.
   - Компоненты:
     - `components/HeaderBar.tsx` — шапка (логотип, погода, уведомления, аватар, баланс).
     - `components/UserCard.tsx` — карточка пользователя.
     - `components/Icon.tsx` — единый SVG-икон-пак.
   - Папка `public/assets/` — дефолтные ассеты (можете заменить, а пути задать в `assets.ts`).

3) **sql/**
   - `bonus_and_agreements.sql` — DDL + базовые данные для бонусов и пользовательских соглашений (без миграций).

Установка
---------
1) **Бэкап** текущего кода.
2) Распаковать архив в корень проекта и **перенести файлы по местам**:
   - `backend/*` → в ваш бэкенд (`/var/www/fishtrackpro/backend`).
   - `frontend/*` → во фронт.
   - `sql/bonus_and_agreements.sql` — выполните в MySQL вручную.
3) В `.env` добавьте (при необходимости):
   - `AI_MODERATION_ENABLED=true`
   - `AI_MODERATION_PROVIDER=auto`  (openai|yandex|auto|none)
   - `OPENAI_API_KEY=...` (если используете OpenAI)
   - `YANDEX_GPT_KEY=...` `YANDEX_GPT_FOLDER_ID=...` (если используете Yandex)
   - `APP_LOGO_URL=/assets/logo.svg`, `APP_AVATAR_PLACEHOLDER=/assets/avatar.png`, `APP_BG_PATTERN=/assets/pattern.svg`
   - `OPENWEATHER_KEY=...`
4) В `routes/api.php` вставьте строки из `backend/docs/routes_snippet.txt` в блок `Route::prefix('v1')->group(...)`.
5) `php artisan storage:link` (1 раз).
6) Перезапустите PHP-FPM/Nginx при необходимости.

Проверка
--------
- `GET /api/v1/rating?range=month`
- `GET /api/v1/friends?scope=mutual&userId=1`
- `POST /api/v1/catch/<built-in function id>/comments`  с `body=...` — вернёт `is_approved=true|false` и `ai`-мету.
- `POST /api/v1/upload` с `file` или `files[]` — массив URL.
- `GET /api/v1/weather?lat=55.75&lng=37.61` — даже без ключа вернёт `200` и описание ошибки в JSON.
