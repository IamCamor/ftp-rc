# S12: Кластеры на карте, загрузка фото, серверная админка, POST для событий/клубов

## Frontend
```bash
cd frontend
npm i leaflet react-leaflet react-leaflet-cluster
```
- Карта: `src/ui/components/map/MapView.tsx` — кластеризация (переключатель), мини-галерея в попапе.
- Добавление фото к точке — в диалоге добавления (MapScreen).
- Формы: `EventForm.tsx`, `ClubForm.tsx` — с загрузкой фото/логотипа.

## Backend
- Новые маршруты:
  - `POST /api/events` → создание события
  - `POST /api/events/{id}/photo` → загрузка фото
  - `POST /api/clubs` → создание клуба
  - `POST /api/clubs/{id}/logo` → загрузка логотипа
  - `POST /api/map/points/{id}/photo` → загрузка фото точки
- Миграции: `2025_01_12_000000_add_photos_to_points_events.php` (не забудь `php artisan migrate`).
- Storage:
```bash
php artisan storage:link
```

## Admin (Blade)
Подключи в `routes/web.php`:
```php
require base_path('routes/web_admin.php');
```
Панель: `/admin`, разделы — Комментарии, Точки, Пользователи. Дизайн — глассморфизм, тёмная тема.

## Роли
Базовая таблица ролей/связей уже есть. Хочешь spatie/laravel-permission?
```bash
composer require spatie/laravel-permission
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"
php artisan migrate
```
(Дальше заменим наш RoleMiddleware на spatie middleware — по запросу.)

## Платежи, письма
- Stripe/YooKassa webhooks уже готовы (см. S11).
- Письма: Blade-шаблоны в `resources/views/emails/`.
