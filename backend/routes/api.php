<?php

require __DIR__.'/api_notifications.php';

use Illuminate\Support\Facades\Route;

// ========== Auth & Misc ==========
use App\Http\Controllers\Api\Auth\SocialAuthController;
use App\Http\Controllers\Api\Bot\TelegramBotController;
use App\Http\Controllers\Api\PushController;
use App\Http\Controllers\Api\AnalyticsController;

// ========== Core ==========
use App\Http\Controllers\Api\MapController;
use App\Http\Controllers\Api\CatchesController;
use App\Http\Controllers\Api\FeedController;
use App\Http\Controllers\Api\EventsController;
use App\Http\Controllers\Api\ClubsController;
use App\Http\Controllers\Api\ChatsController;
use App\Http\Controllers\Api\NotificationsController;
use App\Http\Controllers\Api\WeatherController;

// ========== Public ==========
use App\Http\Controllers\Api\PublicApiController;

// ========== Payments & Webhooks ==========
use App\Http\Controllers\Api\PaymentsController;
use App\Http\Controllers\Api\Webhooks\StripeWebhookController;
use App\Http\Controllers\Api\Webhooks\YookassaWebhookController;

// ========== Admin ==========
use App\Http\Controllers\Api\Admin\AdminCommentsController;
use App\Http\Controllers\Api\Admin\AdminPointsController;
use App\Http\Controllers\Api\Admin\AdminUsersController;

// ---- Auth (social stubs) ----
Route::prefix('auth')->group(function () {
    Route::post('/google', [SocialAuthController::class, 'google']);
    Route::post('/apple', [SocialAuthController::class, 'apple']);
    Route::post('/telegram', [SocialAuthController::class, 'telegram']);
});

// ---- Bot / Push / Analytics ----
Route::post('/bot/telegram/webhook', [TelegramBotController::class, 'webhook']);
Route::post('/push/register', [PushController::class, 'register']);
Route::post('/push/test', [PushController::class, 'test']);
Route::post('/analytics/event', [AnalyticsController::class, 'store']);

// ---- Map ----
Route::get('/map/points', [MapController::class, 'index']);
Route::post('/map/points', [MapController::class, 'store']);
Route::post('/map/points/{id}/photo', [MapController::class, 'photo']);

// ---- Catches ----
Route::get('/catches', [CatchesController::class, 'index']);
Route::post('/catches', [CatchesController::class, 'store']);
Route::post('/catches/{id}/media', [CatchesController::class, 'uploadMedia']);
Route::post('/catches/{id}/like', [CatchesController::class, 'like']);
Route::post('/catches/{id}/comment', [CatchesController::class, 'comment']);

// ---- Feed ----
Route::get('/feed', [FeedController::class, 'index']);

// ---- Events ----
Route::get('/events', [EventsController::class, 'index']);
Route::post('/events', [EventsController::class, 'store']);
Route::post('/events/{id}/photo', [EventsController::class, 'photo']);

// ---- Clubs ----
Route::get('/clubs', [ClubsController::class, 'index']);
Route::post('/clubs', [ClubsController::class, 'store']);
Route::post('/clubs/{id}/logo', [ClubsController::class, 'logo']);

// ---- Chats ----
Route::get('/chats', [ChatsController::class, 'index']);
Route::post('/chats/{id}/message', [ChatsController::class, 'send']);

// ---- Notifications ----
Route::get('/notifications', [NotificationsController::class, 'index']);

// ---- Weather ----
Route::get('/weather', [WeatherController::class, 'show']);

// ---- Public API ----
Route::prefix('public')->group(function () {
    Route::get('/users/{slug}', [PublicApiController::class, 'user']);
    Route::get('/catches/{id}', [PublicApiController::class, 'catch']);
});

// ---- Payments ----
Route::get('/plans', [PaymentsController::class, 'plans']);
Route::post('/create-checkout', [PaymentsController::class, 'createCheckout']);
Route::post('/highlight-point', [PaymentsController::class, 'highlightPoint']);
Route::get('/subscription', [PaymentsController::class, 'subscriptionStatus']);
Route::post('/subscription/cancel', [PaymentsController::class, 'cancelSubscription']);

// ---- Webhooks ----
Route::post('/webhooks/stripe', [StripeWebhookController::class, 'handle']);
Route::post('/webhooks/yookassa', [YookassaWebhookController::class, 'handle']);

// ---- Admin ----
Route::prefix('admin')->group(function () {
    Route::get('/comments/pending', [AdminCommentsController::class, 'pending']);
    Route::post('/comments/{id}/approve', [AdminCommentsController::class, 'approve']);
    Route::post('/comments/{id}/reject', [AdminCommentsController::class, 'reject']);

    Route::get('/points/pending', [AdminPointsController::class, 'pending']);
    Route::post('/points/{id}/approve', [AdminPointsController::class, 'approve']);
    Route::post('/points/{id}/reject', [AdminPointsController::class, 'reject']);

    Route::get('/users', [AdminUsersController::class, 'index']);
    Route::post('/users/{id}/role', [AdminUsersController::class, 'setRole']);
});
