<?php
return [
    'assets' => [
        // Можно заменить на CDN или ваш хостинг
        'logo_url' => env('APP_LOGO_URL', '/assets/logo.svg'),
        'avatar_placeholder' => env('APP_AVATAR_PLACEHOLDER', '/assets/avatar.png'),
        'bg_pattern' => env('APP_BG_PATTERN', '/assets/pattern.svg'),
    ],
    'features' => [
        'ai_moderation' => env('AI_MODERATION_ENABLED', true),
        'ai_provider' => env('AI_MODERATION_PROVIDER', 'auto'), // auto|openai|yandex|none
        'ai_threshold' => env('AI_MODERATION_THRESHOLD', 0.6),
    ],
    'providers' => [
        'openai' => [
            'api_key' => env('OPENAI_API_KEY', ''),
            'base'    => env('OPENAI_BASE', 'https://api.openai.com/v1'),
            'model'   => env('OPENAI_MODERATION_MODEL', 'omni-moderation-latest'),
        ],
        'yandex' => [
            'api_key' => env('YANDEX_GPT_KEY', ''),
            'folder_id' => env('YANDEX_GPT_FOLDER_ID', ''),
            'endpoint' => env('YANDEX_GPT_ENDPOINT', 'https://llm.api.cloud.yandex.net/foundationModels/v1/completion'),
            'model' => env('YANDEX_GPT_MODEL', 'yandexgpt-lite'),
        ],
    ],
];
