<?php

use Illuminate\Support\Facades\Route;

require base_path('routes/api_s7.php');
require base_path('routes/api_public.php');
require base_path('routes/api_payments.php');
require base_path('routes/api_admin.php');

use App\Http\Controllers\Api\Auth\SocialAuthController;
use App\Http\Controllers\Api\Bot\TelegramBotController;
use App\Http\Controllers\Api\PushController;
use App\Http\Controllers\Api\AnalyticsController;
// Core demo endpoints (map, catches, feed, events, clubs, chats, notifications, weather)
use App\Http\Controllers\Api\MapController;
use App\Http\Controllers\Api\CatchesController;
use App\Http\Controllers\Api\FeedController;
use App\Http\Controllers\Api\EventsController;
use App\Http\Controllers\Api\ClubsController;
use App\Http\Controllers\Api\ChatsController;
use App\Http\Controllers\Api\NotificationsController;

use App\Http\Controllers\Api\BillingController;
use App\Http\Controllers\Api\BannersController;
use App\Http\Controllers\Api\SearchController;
use App\Http\Controllers\Api\WeatherController;

Route::get('/map/points', [MapController::class, 'index']);
Route::post('/map/points', [MapController::class, 'store']);

Route::get('/catches', [CatchesController::class, 'index']);
Route::post('/catches', [CatchesController::class, 'store']);
Route::post('/catches/{id}/media', [CatchesController::class, 'uploadMedia']);
Route::post('/catches/{id}/like', [CatchesController::class, 'like']);
Route::post('/catches/{id}/comment', [CatchesController::class, 'comment']);

Route::get('/feed', [FeedController::class, 'index']);
Route::get('/events', [EventsController::class, 'index']);
Route::get('/clubs', [ClubsController::class, 'index']);
Route::get('/chats', [ChatsController::class, 'index']);
Route::post('/chats/{id}/message', [ChatsController::class, 'send']);
Route::get('/notifications', [NotificationsController::class, 'index']);

Route::get('/weather', [WeatherController::class, 'show']);


Route::prefix('auth')->group(function () {
    Route::post('/google', [SocialAuthController::class, 'google']);
    Route::post('/apple', [SocialAuthController::class, 'apple']);
    Route::post('/telegram', [SocialAuthController::class, 'telegram']);
});

Route::post('/bot/telegram/webhook', [TelegramBotController::class, 'webhook']);
Route::post('/analytics/event', [AnalyticsController::class, 'store']);
Route::post('/push/register', [PushController::class, 'register']);
Route::post('/push/test', [PushController::class, 'test']);



Route::middleware('auth:sanctum')->group(function(){ Route::post('/billing/payment',[BillingController::class,'createPayment']); Route::get('/billing/subscription',[BillingController::class,'mySubscription']); Route::post('/billing/subscription/cancel',[BillingController::class,'cancel']); });
Route::post('/billing/webhook/{provider}',[BillingController::class,'webhook']);
Route::get('/banners/slots',[BannersController::class,'slots']);
Route::get('/banners/slot/{code}',[BannersController::class,'listForSlot']);
Route::post('/banners/{id}/impression',[BannersController::class,'impression'])->middleware('throttle:60,1');
Route::get('/search',[SearchController::class,'global']);
Route::get('/weather',[WeatherController::class,'current']);