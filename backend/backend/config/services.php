<?php
return [
  'stripe' => [
    'key' => env('STRIPE_PUBLIC'),
    'secret' => env('STRIPE_SECRET'),
    'webhook_secret' => env('STRIPE_WEBHOOK_SECRET'),
  ],
  'yookassa' => [
    'shop_id' => env('YOOKASSA_SHOP_ID'),
    'secret' => env('YOOKASSA_SECRET_KEY'),
    'webhook_secret' => env('YOOKASSA_WEBHOOK_SECRET'),
  ],
];
