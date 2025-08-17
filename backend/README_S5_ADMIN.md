FishTrackPro — S5 Admin UI (Blade)
==================================
1) Скопируй файлы в backend/.
2) В `routes/web.php` добавь строку: `require base_path('routes/web_admin.php');`
3) Прогони миграции: `php artisan migrate`
4) Сделай себя админом: через tinker установи is_admin=true для своего пользователя.
5) Открой: http://127.0.0.1:8000/admin (требуется аутентификация).
