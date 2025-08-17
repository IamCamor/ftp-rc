FishTrackPro S1+S2 Patch (fresh build)
======================================

Backend:
1) Скопируй папку `backend/` в Laravel-проект по соответствующим путям.
2) Вставь фрагменты из `backend/routes/api_s1s2_patch.php` в `routes/api.php`.
3) Команды:
   php artisan migrate
   php artisan storage:link
   php artisan queue:work
4) Флаг модерации: FEATURE_AI_MODERATION=true (config/features.php).

Frontend:
1) Скопируй файлы из `frontend/` в свою папку `frontend/`.
2) Импортируй функции из `src/ui/data/api_patch_s2.ts` в экраны/слои данных.
3) В `.env` фронта:
   VITE_USE_MOCKS=false
   VITE_API_BASE=http://localhost/api
4) npm install axios
   npm run dev
