<?php

return [
    'telegram' => [ 'bot_token' => env('TELEGRAM_BOT_TOKEN') ],
    'fcm' => [ 'server_key' => env('FCM_SERVER_KEY') ],
    'openweather'=>['key'=>env('OPENWEATHER_API_KEY')],
    'stripe'=>['key'=>env('STRIPE_KEY'),'secret'=>env('STRIPE_SECRET')],
    'yookassa'=>['shop_id'=>env('YOOKASSA_SHOP_ID'),'secret'=>env('YOOKASSA_SECRET')],
    'paypal'=>['client_id'=>env('PAYPAL_CLIENT_ID'),'secret'=>env('PAYPAL_SECRET')],
    'sber'=>['user'=>env('SBER_USER'),'pass'=>env('SBER_PASS')],
    'yandex_pay'=>['merchant_id'=>env('YANDEX_PAY_MERCHANT_ID'),'secret'=>env('YANDEX_PAY_SECRET')],
    'google' => [
        'client_id'     => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'redirect'      => env('GOOGLE_REDIRECT_URI'), // https://api.fishtrackpro.ru/auth/google/callback
    ],
    'vkontakte' => [
        'client_id'     => env('VKONTAKTE_CLIENT_ID'),
        'client_secret' => env('VKONTAKTE_CLIENT_SECRET'),
        'redirect'      => env('VKONTAKTE_REDIRECT_URI'), // https://api.fishtrackpro.ru/auth/vk/callback
    ],
    'yandex' => [
        'client_id'     => env('YANDEX_CLIENT_ID'),
        'client_secret' => env('YANDEX_CLIENT_SECRET'),
        'redirect'      => env('YANDEX_REDIRECT_URI'), // https://api.fishtrackpro.ru/auth/yandex/callback
    ],
    'apple' => [
        'client_id'     => env('APPLE_CLIENT_ID'),
        'client_secret' => env('APPLE_CLIENT_SECRET'), // JWT secret (см. доки провайдера)
        'redirect'      => env('APPLE_REDIRECT_URI'), // https://api.fishtrackpro.ru/auth/apple/callback
    ],
];
