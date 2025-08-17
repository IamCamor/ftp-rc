# FishTrackPro — Upgrade Pack
В этом архиве:
- Backend: комментарии/лайки, очередь модерации, письма, крон.
- Frontend: нижнее меню, FAB, формы добавления, карта с фильтрами, AR-экран.

## Быстрый старт фронтенда (моки)
```
cd frontend
npm install
npm run dev:mock
```
Открой http://localhost:5173

## Backend
Добавьте файлы из `backend/` в ваш backend проект, затем выполните:
```
php artisan migrate
php artisan queue:work
php artisan schedule:work
```
Для отправки писем используйте MAIL_* настройки. Дайджест уходит каждый день в 08:00 (см. app/Console/Kernel.php).
