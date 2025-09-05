#!/usr/bin/env bash
set -euo pipefail

FRONT="./frontend"
BACK="./backend"

#######################################
# 1) FRONT: единый BASE и аккуратные вызовы
#######################################
mkdir -p "$FRONT/src"

cat > "$FRONT/src/api.ts" <<'EOF'
export const API_BASE = 'https://api.fishtrackpro.ru/api/v1';

type Method = 'GET'|'POST'|'PUT'|'PATCH'|'DELETE';

async function http<T>(
  path: string,
  { method='GET', body, auth=false, query }: { method?: Method; body?: any; auth?: boolean; query?: Record<string, any> } = {}
): Promise<T> {
  const url = new URL(API_BASE + path);
  if (query) {
    Object.entries(query).forEach(([k,v])=>{
      if (v !== undefined && v !== null) url.searchParams.set(k, String(v));
    });
  }

  // Публичные: без cookie → проще CORS
  // Приватные: с cookie (Sanctum/сессия)
  const fetchOpts: RequestInit = {
    method,
    mode: 'cors',
    credentials: auth ? 'include' : 'omit',
    headers: {
      ...(body instanceof FormData ? {} : {'Content-Type':'application/json'})
    },
    body: body ? (body instanceof FormData ? body : JSON.stringify(body)) : undefined
  };

  const res = await fetch(url.toString(), fetchOpts);
  if (!res.ok) {
    const txt = await res.text().catch(()=> '');
    throw new Error(`${res.status} ${res.statusText} :: ${txt.slice(0,400)}`);
  }
  // На /notifications может быть 204
  if (res.status === 204) return {} as T;
  const ct = res.headers.get('content-type') || '';
  if (ct.includes('application/json')) return res.json() as Promise<T>;
  return (await res.text()) as unknown as T;
}

/* ==== Публичные ==== */
export const api = {
  feed: (params: {limit?:number; offset?:number; sort?:'new'|'top'; fish?:string; near?:string}={}) =>
    http('/feed', { query: params }),

  points: (params: {limit?:number; bbox?:string; filter?:string}={}) =>
    http('/map/points', { query: params }),

  catchById: (id: number|string) =>
    http(`/catch/${id}`),

  weather: (params: {lat:number; lng:number; dt?:number}) =>
    http('/weather', { query: params }),

  addCatch: (payload: any) =>
    http('/catches', { method: 'POST', body: payload }), // публичная публикация допускается гостем, если бек так настроен

  addPlace: (payload: any) =>
    http('/points', { method: 'POST', body: payload }),

  /* ==== Приватные (cookies required) ==== */
  me: () => http('/profile/me', { auth:true }),
  notifications: () => http('/notifications', { auth:true }),
  followToggle: (userId: number|string) => http(`/follow/${userId}`, { method: 'POST', auth:true }),
  likeToggle: (catchId: number|string) => http(`/catch/${catchId}/like`, { method: 'POST', auth:true }),
  addComment: (catchId: number|string, payload: {text:string}) => http(`/catch/${catchId}/comments`, { method:'POST', body: payload, auth:true }),
};
EOF

echo "✅ Front: src/api.ts обновлён (все пути -> /api/v1, CORS дружественные опции)"

#######################################
# 2) BACK: Laravel CORS config
#######################################
mkdir -p "$BACK/config"

cat > "$BACK/config/cors.php" <<'EOF'
<?php

return [

    'paths' => [
        'api/*',
        'sanctum/csrf-cookie',
        // если есть не-префиксные web-ручки для api:
        // 'feed', 'map/*', 'profile/*', 'notifications',
    ],

    'allowed_methods' => ['*'],

    // Разрешаем фронту
    'allowed_origins' => [
        'https://www.fishtrackpro.ru',
    ],

    'allowed_origins_patterns' => [],

    // На публичных ручках JS не шлёт cookie. Но если придут —
    // допустим кросс-домен с учётом allowed_origins.
    'supports_credentials' => true,

    'allowed_headers' => ['*'],

    'exposed_headers' => [
        // можно добавить 'X-Total-Count' и т.п. если нужно
    ],

    'max_age' => 3600,

];
EOF

echo "✅ Back: config/cors.php записан"

#######################################
# 3) Подсказка для nginx (если перехватываете CORS тут)
#######################################
mkdir -p "./ops"
cat > "./ops/nginx_cors_example.conf" <<'EOF'
# Фрагмент: подключайте внутри server {} для api.fishtrackpro.ru
# Используйте, только если хотите решать CORS на уровне nginx.
# Если доверяете Laravel-cors — это не обязательно.

# Разрешить фронтовый домен
set $cors '';
if ($http_origin = "https://www.fishtrackpro.ru") {
  set $cors 'true';
}

location ~* ^/api/ {
  if ($request_method = OPTIONS) {
    add_header 'Access-Control-Allow-Origin' $http_origin always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Access-Control-Allow-Methods' 'GET,POST,PUT,PATCH,DELETE,OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Authorization,Content-Type,Accept,Origin,X-Requested-With' always;
    add_header 'Access-Control-Max-Age' 3600;
    return 204;
  }

  if ($cors = 'true') {
    add_header 'Access-Control-Allow-Origin' $http_origin always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
  }

  # обычный прокси на php-fpm/laravel
  try_files $uri /index.php?$query_string;
}
EOF

echo "ℹ️  Ops: пример ops/nginx_cors_example.conf создан (используйте при необходимости)"

#######################################
# 4) Подсказки по маршрутам
#######################################
echo
echo "Напоминание:"
echo "— Бэк должен экспонировать ровно эти пути: /api/v1/feed, /api/v1/map/points, /api/v1/profile/me, /api/v1/notifications и т.д."
echo "  У вас в routes/api.php уже есть префикс v1 — проверьте, что фронт и бэк совпадают по префиксу /api/v1."
echo
echo "Готово. После деплоя на бэке выполните: php artisan config:clear && php artisan config:cache"