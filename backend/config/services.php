<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

'openweather'=>['key'=>env('OPENWEATHER_API_KEY')],
'stripe'=>['key'=>env('STRIPE_KEY'),'secret'=>env('STRIPE_SECRET')],
'yookassa'=>['shop_id'=>env('YOOKASSA_SHOP_ID'),'secret'=>env('YOOKASSA_SECRET')],
'paypal'=>['client_id'=>env('PAYPAL_CLIENT_ID'),'secret'=>env('PAYPAL_SECRET')],
'sber'=>['user'=>env('SBER_USER'),'pass'=>env('SBER_PASS')],
'yandex_pay'=>['merchant_id'=>env('YANDEX_PAY_MERCHANT_ID'),'secret'=>env('YANDEX_PAY_SECRET')],


    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'resend' => [
        'key' => env('RESEND_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

];
