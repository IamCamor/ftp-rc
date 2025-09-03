<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],

    // НЕЛЬЗЯ '*', указываем ровно ваши фронт-домены
    'allowed_origins' => [
        'https://www.fishtrackpro.ru',
        'https://fishtrackpro.ru',
    ],
    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],
    'exposed_headers' => [],

    // важно
    'supports_credentials' => true,

    'max_age' => 0,
];