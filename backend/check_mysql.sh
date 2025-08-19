# check_mysql.sh

#!/usr/bin/env bash
set -euo pipefail

# === Читаем .env ===
ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Файл $ENV_FILE не найден!"
  exit 1
fi

# Функция для чтения значения по ключу
function get_env() {
  local key="$1"
  grep -E "^${key}=" "$ENV_FILE" | cut -d '=' -f2- | tr -d '"' | tr -d "'"
}

DB_HOST=$(get_env DB_HOST)
DB_PORT=$(get_env DB_PORT)
DB_DATABASE=$(get_env DB_DATABASE)
DB_USERNAME=$(get_env DB_USERNAME)
DB_PASSWORD=$(get_env DB_PASSWORD)

# === Проверка соединения ===
echo "Проверка подключения к MySQL..."
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT VERSION();" >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "Ошибка: не удалось подключиться к MySQL с указанными параметрами!"
  exit 2
fi

echo "Соединение установлено."

# === Проверка существования базы ===
DB_EXISTS=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" -N -B -e "SHOW DATABASES LIKE '${DB_DATABASE}';")

if [ "$DB_EXISTS" == "$DB_DATABASE" ]; then
  echo "База '${DB_DATABASE}' существует."
else
  echo "Ошибка: база '${DB_DATABASE}' отсутствует!"
  exit 3
fi

# === Тестовый запрос ===
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "SHOW TABLES;" >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "Тестовый запрос выполнен успешно. MySQL настройки корректны ✅"
else
  echo "Ошибка: не удалось выполнить запрос в базе '${DB_DATABASE}'"
  exit 4
fi
