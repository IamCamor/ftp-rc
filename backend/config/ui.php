<?php
return [
  'logo' => env('UI_LOGO', '/logo.svg'),
  'bg' => env('UI_BG', ''),
  'primary' => env('UI_PRIMARY', '#0ea5e9'),
  'secondary' => env('UI_SECONDARY', '#22c55e'),
  'glass' => [
    'opacity' => env('UI_GLASS_OPACITY', 0.6),
    'blur' => env('UI_GLASS_BLUR', 12),
    'saturation' => env('UI_GLASS_SAT', 140),
  ],
   'logo_url'        => env('UI_LOGO_URL', 'https://cdn.fishtrackpro.ru/assets/logo.svg'),
    'default_avatar'  => env('UI_DEFAULT_AVATAR', 'https://cdn.fishtrackpro.ru/assets/default-avatar.png'),
    'bg_pattern'      => env('UI_BG_PATTERN', 'https://cdn.fishtrackpro.ru/assets/pattern.png'),

];
