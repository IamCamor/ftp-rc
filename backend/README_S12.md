# S12: Уведомления + Очереди + CRON дайджест

**Что добавлено**
- REST: список/фильтры/прочитано/настройки, тест-отправка.
- Таблицы `notifications`, `notification_settings`.
- Очереди (database) и джоб `SendDailyDigest`.
- CRON: ежедневный дайджест в 09:00 Europe/Amsterdam.

**Шаги**
```bash
# 1) .env
echo 'QUEUE_CONNECTION=database' >> .env
php artisan queue:table && php artisan migrate

# 2) Миграции + сидер (опц.)
php artisan migrate

# 3) Запуск воркера и планировщика
php artisan queue:work
php artisan schedule:work
```

**Подключение роутов**
Добавь в конец `routes/api.php`:
```php
require __DIR__.'/api_notifications.php';
```
