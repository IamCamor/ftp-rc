FishTrackPro — Full Controllers Patch
=====================================

1) Скопируй файлы из `backend/app/Http/Controllers/Api/` в проект.
2) Удали файлы-патчи типа *_patch.php и *_append.php в контроллерах.
3) Добавь маршруты из `backend/routes/api_full_example.php` в `routes/api.php`.
4) Убедись, что модели существуют: MapPoint, CatchRecord, Media, CatchLike, CatchComment, ModerationItem.
5) Очисти кеши и запусти сервер:
   php artisan route:clear && php artisan config:clear && php artisan serve
