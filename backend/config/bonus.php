<?php

return [
    'pro_cost' => 1000,
    'daily_cap' => 300,
    'referral_unique_window_days' => 365,

    'actions' => [
        'register' => ['points' => 100, 'daily_limit' => 1],
        'profile_complete' => ['points' => 50, 'daily_limit' => 1],
        'first_catch' => ['points' => 200, 'daily_limit' => 1],
        'catch_add' => ['points' => 50, 'daily_limit' => 50],
        'comment_add' => ['points' => 10, 'daily_limit' => 10],
        'like_add' => ['points' => 5, 'daily_limit' => 20],
        'friend_add' => ['points' => 20, 'daily_limit' => 10],
        'referral_registered' => ['points' => 200, 'daily_limit' => 10],
        'event_participation' => ['points' => 100, 'daily_limit' => 5],
        'blog_post_published' => ['points' => 50, 'daily_limit' => 5],
    ],

    'fraud' => [
        'min_seconds_between_same_action' => 10,
        'like_receiver_no_points' => true,
    ],
];
