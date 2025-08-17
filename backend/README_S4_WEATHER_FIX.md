FishTrackPro — S4 Weather Fix
=============================

Этот патч добавляет надёжный WeatherController с кэшем в БД, безопасной обработкой ошибок
и мок-ответом, если фича выключена или нет API-ключа.

Что входит:
- app/Http/Controllers/Api/WeatherController.php
- app/Models/WeatherCache.php
- database/migrations/2025_01_04_000010_create_weather_cache_table.php (с защитой hasTable)
- config/features.php (добавлены флаги payments/banners/weather/ar_mode — объединяй аккуратно)
- routes/api_s4_weather.php (фрагмент для routes/api.php)

Шаги:
1) Скопируй файлы в проект (с сохранением путей).
2) Вставь маршрут из routes/api_s4_weather.php в routes/api.php.
3) В .env добавь:
   FEATURE_WEATHER=true
   OPENWEATHER_API_KEY=your_key_here
4) Примени миграцию:
   php artisan migrate
5) Проверка:
   GET /api/weather?lat=55.75&lng=37.62&lang=ru&units=metric

Если ключ не задан или сеть недоступна — вернётся "source":"mock"/"fallback-mock".
