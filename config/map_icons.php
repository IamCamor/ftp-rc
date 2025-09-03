<?php

/**
 * Карта иконок для типов точек на карте.
 * Для каждого типа можно указать строку (URL) или расширенный объект:
 * ['url' => '...', 'size' => [w,h], 'anchor' => [x,y], 'popup' => [x,y]]
 */
return [
    'types' => [
        'spot' => [
            'url' => env('ICON_SPOT', '/icons/spot.png'),
            'size' => [32, 32],
            'anchor' => [16, 32],
            'popup' => [0, -28],
        ],
        'store' => [
            'url' => env('ICON_STORE', '/icons/store.png'),
            'size' => [28, 28],
            'anchor' => [14, 28],
            'popup' => [0, -24],
        ],
        'base' => env('ICON_BASE', '/icons/base.png'),
        'slip' => env('ICON_SLIP', '/icons/slip.png'),
        'farm' => env('ICON_FARM', '/icons/farm.png'),
        'event' => [
            'url' => env('ICON_EVENT', '/icons/event.png'),
            'size' => [30, 30],
            'anchor' => [15, 30],
            'popup' => [0, -26],
        ],
        'club' => env('ICON_CLUB', '/icons/club.png'),
        'highlight' => [
            'url' => env('ICON_HIGHLIGHT', '/icons/highlight.png'),
            'size' => [36, 36],
            'anchor' => [18, 36],
            'popup' => [0, -32],
        ],
    ],
    'default' => [
        'url' => env('ICON_DEFAULT', '/icons/default.png'),
        'size' => [26, 26],
        'anchor' => [13, 26],
        'popup' => [0, -22],
    ],
];
