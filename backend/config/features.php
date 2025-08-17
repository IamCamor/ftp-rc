<?php
return [
  'ai_moderation' => env('FEATURE_AI_MODERATION', true),
  'i18n' => env('FEATURE_I18N', true),
  'themes' => env('FEATURE_THEMES', true),
  'ar_mode' => env('FEATURE_AR', true),
  'weather' => env('FEATURE_WEATHER', true),
  'payments' => env('FEATURE_PAYMENTS', true),
  'banners' => env('FEATURE_BANNERS', true),
];
