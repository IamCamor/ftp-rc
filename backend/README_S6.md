FishTrackPro — Sprint S6 Patch (i18n, Themes, AR)
=================================================

Frontend:
- i18n на 15 языков (react-i18next), ленивые JSON в src/i18n/locales
- Конфиг брендинга и глассморфизма (src/config/ui.ts)
- Тема MUI (src/ui/theme.tsx)
- Нижнее меню (src/ui/components/BottomNav.tsx)
- AR экран (src/ui/screens/ARView.tsx) — камера + компас + оверлеи

Backend:
- /api/config/ui — отдаёт бренд/флаги/i18n (ConfigController)
- config/ui.php + расширенные feature flags

Как применить
-------------
Frontend:
1) Скопируй файлы из папки frontend/.
2) Включи i18n: импортируй `./i18n` в `src/ui/App.tsx`.
3) Подключи тему и BottomNav (см. diff в src/ui/App_shell_s6_diff.txt).
4) Добавь маршрут `/ar` на ARView.
5) Обнови `.env` по образцу `.env.s6.example`.

Backend:
1) Скопируй файлы из папки backend/.
2) Вставь маршруты из routes/api_s6_config.php в routes/api.php.
3) Обнови .env из backend/.env.s6.append (или добавь переменные).
4) Перезапусти:
   php artisan config:clear && php artisan route:clear

Проверка
--------
- GET /api/config/ui — возвращает JSON с брендингом/фичами.
- Открой фронт: смена языка через `localStorage.setItem('lang','de')` и перезагрузку.
- Открой /ar — появится камера и карточки ближайших точек.

Примечания
----------
- Для iOS нужно разрешение камеры по HTTPS; в dev можно тестировать в Safari с `https://localhost` (self-signed) или на Android/Chrome по http.
- Если нет точек, ARView показывает демо-точки. Подключи реальные через API.
