<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\MapController;
use App\Http\Controllers\Api\CatchesController;
use App\Http\Controllers\Api\EventsController;
use App\Http\Controllers\Api\ClubsController;
use App\Http\Controllers\Api\PlansController;
use App\Http\Controllers\Api\PaymentsController;
use App\Http\Controllers\Api\WeatherController;
use App\Http\Controllers\Api\NotificationsController;

Route::get('/health', [HealthController::class,'index']);

Route::get('/map/points', [MapController::class,'index']);
Route::post('/map/points', [MapController::class,'store']);
Route::post('/map/points/{id}/photo', [MapController::class,'uploadPhoto']);

Route::post('/catches', [CatchesController::class,'store']);
Route::post('/catches/{id}/media', [CatchesController::class,'uploadMedia']);

Route::post('/events', [EventsController::class,'store']);
Route::post('/events/{id}/photo', [EventsController::class,'uploadPhoto']);

Route::post('/clubs', [ClubsController::class,'store']);
Route::post('/clubs/{id}/logo', [ClubsController::class,'uploadLogo']);

Route::get('/plans', [PlansController::class,'index']);
Route::post('/create-checkout', [PaymentsController::class,'createCheckout']);

Route::get('/weather', [WeatherController::class,'currentPlusDaily']);

Route::post('/webhooks/stripe', [PaymentsController::class,'stripeWebhook']);
Route::post('/webhooks/yookassa', [PaymentsController::class,'yookassaWebhook']);

Route::get('/notifications', [NotificationsController::class,'index']);
Route::post('/notifications/{id}/read', [NotificationsController::class,'markRead']);
Route::post('/notifications/read-all', [NotificationsController::class,'readAll']);
Route::get('/notifications/settings', [NotificationsController::class,'settings']);
Route::post('/notifications/settings', [NotificationsController::class,'saveSettings']);
Route::post('/notifications/create-test', [NotificationsController::class,'createTest']);
