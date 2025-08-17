<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\MapController;
use App\Http\Controllers\Api\CatchesController;
use App\Http\Controllers\Api\FeedController;
use App\Http\Controllers\Api\ModerationController;

use App\Http\Controllers\Api\FriendsController;
use App\Http\Controllers\Api\ClubsController;
use App\Http\Controllers\Api\EventsController;
use App\Http\Controllers\Api\NotificationsController;
use App\Http\Controllers\Api\ChatsController;
use App\Http\Controllers\Api\BillingController;
use App\Http\Controllers\Api\BannersController;
use App\Http\Controllers\Api\SearchController;
use App\Http\Controllers\Api\WeatherController;

use App\Http\Controllers\Api\ConfigController;

/*
|--------------------------------------------------------------------------
| API Routes — FishTrackPro
|--------------------------------------------------------------------------
| Публичные: карта (чтение), фиды, события/клубы (списки).
| Защищённые: создание/редактирование, лайки/комменты, друзья/клубы/ивенты,
| уведомления, чаты.
| Админ: модерация (очередь/approve/reject).
|--------------------------------------------------------------------------
*/

// --- Healthcheck (опционально)
Route::get('/health', fn() => ['ok' => true, 'time' => now()->toISOString()]);

// --- Публичные фиды
Route::get('/feed/global', [FeedController::class, 'global']);
Route::get('/feed/local',  [FeedController::class, 'local']);   // near=lat,lng,km
Route::get('/feed/follow', [FeedController::class, 'follow']);  // сейчас = global

// --- Карта (чтение)
Route::get('/map/points', [MapController::class, 'index']);     // ?type=spot,shop,slip,base&featured=1&near=lat,lng,km

// --- Публичные списки S3
Route::get('/events', [EventsController::class, 'index']);      // ?region=...&from=YYYY-MM-DD&to=YYYY-MM-DD
Route::get('/clubs',  [ClubsController::class, 'index']);

// --- Защищённые (Sanctum)
Route::middleware('auth:sanctum')->group(function () {

    // Карта — создание/редактирование
    Route::post('/map/points',            [MapController::class, 'store']);
    Route::put('/map/points/{id}',        [MapController::class, 'update']);
    Route::delete('/map/points/{id}',     [MapController::class, 'destroy']);

    // Уловы
    Route::post('/catches',               [CatchesController::class, 'store']);
    Route::post('/catches/{id}/media',    [CatchesController::class, 'uploadMedia']);

    // Соц. действия
    Route::post('/feed/{id}/like',        [CatchesController::class, 'like']);
    Route::post('/feed/{id}/unlike',      [CatchesController::class, 'unlike']);
    Route::post('/feed/{id}/comment',     [CatchesController::class, 'comment']);

    // Друзья
    Route::get('/friends',                [FriendsController::class, 'index']);
    Route::post('/friends/request',       [FriendsController::class, 'request']);
    Route::post('/friends/{id}/accept',   [FriendsController::class, 'accept']);
    Route::post('/friends/{id}/decline',  [FriendsController::class, 'decline']);

    // Клубы/команды
    Route::post('/clubs',                 [ClubsController::class, 'store']);
    Route::get('/clubs/{id}',             [ClubsController::class, 'show']);
    Route::post('/clubs/{id}/join',       [ClubsController::class, 'join']);
    Route::post('/clubs/{id}/leave',      [ClubsController::class, 'leave']);

    // События
    Route::post('/events',                        [EventsController::class, 'store']);
    Route::post('/events/{id}/subscribe',         [EventsController::class, 'subscribe']);
    Route::post('/events/{id}/unsubscribe',       [EventsController::class, 'unsubscribe']);

    // Уведомления
    Route::get('/notifications',                  [NotificationsController::class, 'index']);   // ?type=&read=
    Route::post('/notifications/{id}/read',       [NotificationsController::class, 'markRead']);

    // Чаты
    Route::get('/chats',                          [ChatsController::class, 'rooms']);
    Route::get('/chats/{roomId}/messages',        [ChatsController::class, 'messages']);
    Route::post('/chats/{roomId}/send',           [ChatsController::class, 'send']);
});

// --- Админка (модерация)
Route::middleware(['auth:sanctum', 'can:admin'])->group(function () {
    Route::get('/admin/moderation',               [ModerationController::class, 'index']);
    Route::post('/admin/moderation/{id}/approve', [ModerationController::class, 'approve']);
    Route::post('/admin/moderation/{id}/reject',  [ModerationController::class, 'reject']);
});


Route::middleware('auth:sanctum')->group(function(){ Route::post('/billing/payment',[BillingController::class,'createPayment']); Route::get('/billing/subscription',[BillingController::class,'mySubscription']); Route::post('/billing/subscription/cancel',[BillingController::class,'cancel']); });
Route::post('/billing/webhook/{provider}',[BillingController::class,'webhook']);
Route::get('/banners/slots',[BannersController::class,'slots']);
Route::get('/banners/slot/{code}',[BannersController::class,'listForSlot']);
Route::post('/banners/{id}/impression',[BannersController::class,'impression'])->middleware('throttle:60,1');
Route::get('/search',[SearchController::class,'global']);
Route::get('/weather', [WeatherController::class, 'index']); 

Route::get('/config/ui', [ConfigController::class, 'ui']);