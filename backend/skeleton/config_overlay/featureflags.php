<?php
return [
  'all_enabled' => env('FEATURE_FLAGS_ALL', true),
  'flags' => [
    'map_google' => false, 'map_osm' => false, 'map_yandex' => false, 'map_2gis' => false,
    'ai_moderation' => true, 'payments' => true, 'ar_mode' => true,
  ]
];
