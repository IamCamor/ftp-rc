<?php

return [

    'paths' => ['api/*', 'oauth/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        'https://www.fishtrackpro.ru',
        'https://fishtrackpro.ru',
        'https://app.fishtrackpro.ru',
        'https://api.fishtrackpro.ru',
    ],

    'allowed_origins_patterns' => [],

    'allowed_headers' => [
        'Content-Type', 'X-Requested-With', 'Authorization',
        'Accept', 'Origin', 'Referer', 'User-Agent', 'Cache-Control',
    ],

    // если токены/куки между доменами НЕ нужны — оставь false
    // если нужны cookie/Authorization с кросс-домена — поставь true
    'supports_credentials' => false,

    'exposed_headers' => ['Link','X-RateLimit-Limit','X-RateLimit-Remaining'],

    // чтобы не резать preflight: хотя бы на 10 минут
    'max_age' => 600,
];