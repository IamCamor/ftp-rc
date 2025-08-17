<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\{HealthController,AuthController,MapController,CatchesController,FeedController,NotificationsController,
  SocialController,ClubsController,ChatsController,EventsController,DirectoriesController,RatingsController,PaymentsController,
  SearchController,WeatherController,AdminController,FlagsController};

Route::get('/health', [HealthController::class, 'index']);
Route::get('/feature-flags', [FlagsController::class, 'index']);

Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);

    // Map & Points
    Route::get('/map/points', [MapController::class, 'index']);
    Route::post('/map/points', [MapController::class, 'store']);
    Route::post('/map/points/{id}/share', [MapController::class, 'share']);
    Route::post('/map/points/{id}/feature', [MapController::class, 'feature']);

    // Catches
    Route::get('/catches', [CatchesController::class, 'list']);
    Route::post('/catches', [CatchesController::class, 'store']);

    // Feed
    Route::get('/feed/global', [FeedController::class, 'global']);
    Route::get('/feed/local', [FeedController::class, 'local']);
    Route::get('/feed/follow', [FeedController::class, 'follow']);
    Route::post('/feed/{catchId}/like', [FeedController::class, 'like']);
    Route::post('/feed/{catchId}/comment', [FeedController::class, 'comment']);

    // Notifications
    Route::get('/notifications', [NotificationsController::class, 'index']);
    Route::post('/notifications/read', [NotificationsController::class, 'read']);

    // Social
    Route::post('/friends/{userId}/request', [SocialController::class, 'request']);
    Route::post('/friends/{userId}/accept', [SocialController::class, 'accept']);
    Route::get('/friends', [SocialController::class, 'list']);

    // Clubs & Teams
    Route::get('/clubs', [ClubsController::class, 'index']);
    Route::post('/clubs', [ClubsController::class, 'store']);
    Route::post('/clubs/{clubId}/join', [ClubsController::class, 'join']);
    Route::get('/clubs/{clubId}/events', [ClubsController::class, 'events']);

    // Chats
    Route::get('/chats', [ChatsController::class, 'index']);
    Route::post('/chats', [ChatsController::class, 'create']);
    Route::get('/chats/{chatId}/messages', [ChatsController::class, 'messages']);
    Route::post('/chats/{chatId}/messages', [ChatsController::class, 'send']);

    // Events
    Route::get('/events', [EventsController::class, 'index']);
    Route::post('/events', [EventsController::class, 'store']);
    Route::post('/events/{id}/subscribe', [EventsController::class, 'subscribe']);

    // Directories
    Route::get('/directories/species', [DirectoriesController::class, 'species']);
    Route::get('/directories/knots', [DirectoriesController::class, 'knots']);
    Route::get('/directories/lures', [DirectoriesController::class, 'lures']);
    Route::get('/directories/gears', [DirectoriesController::class, 'gears']);
    Route::get('/directories/recipes', [DirectoriesController::class, 'recipes']);

    // Ratings & achievements
    Route::get('/ratings/top', [RatingsController::class, 'top']);
    Route::get('/ratings/diversity', [RatingsController::class, 'diversity']);
    Route::get('/ratings/records', [RatingsController::class, 'records']);

    // Payments & subscriptions
    Route::post('/payments/feature-point', [PaymentsController::class, 'featurePoint']);
    Route::post('/subscriptions', [PaymentsController::class, 'subscribe']);
    Route::post('/payments/webhook/{provider}', [PaymentsController::class, 'webhook']);

    // Search
    Route::get('/search', [SearchController::class, 'search']);

    // Weather
    Route::get('/weather/current', [WeatherController::class, 'current']);
    Route::get('/weather/forecast', [WeatherController::class, 'forecast']);
});

Route::middleware(['auth:sanctum','admin'])->group(function () {
    Route::get('/admin/stats', [AdminController::class, 'stats']);
    Route::get('/admin/users', [AdminController::class, 'users']);
    Route::post('/admin/flags', [AdminController::class, 'setFlags']);
});
