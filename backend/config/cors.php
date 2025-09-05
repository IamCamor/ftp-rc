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
