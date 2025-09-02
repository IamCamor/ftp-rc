<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\UploadController;
use App\Http\Controllers\Api\WeatherProxyController;
use App\Http\Controllers\Api\PointsController;
use App\Http\Controllers\Api\FeedController;
use App\Http\Controllers\Api\CatchController;
use App\Http\Controllers\Api\CommentController;
use App\Http\Controllers\Api\LikeController;
use App\Http\Controllers\Api\FollowController;
use App\Http\Controllers\Api\ReferralController;

use App\Http\Controllers\Api\MapController;
use App\Http\Controllers\Api\WeatherController;
use App\Http\Controllers\Api\CatchesController;

use App\Http\Controllers\Api\CommentsReadController;
use App\Http\Controllers\Api\WeatherLocationsController;
use App\Http\Controllers\Api\LeaderboardController;
use App\Http\Controllers\Api\UserCatchesController;

Route::get('/health', fn()=>response()->json(['ok'=>true,'ts'=>now()]));

Route::prefix('v1')->group(function () {
    
Route::get('/catch/{id}/comments', [CommentsReadController::class, 'index']); // если не хотите править ваш CommentController

// Погода — сохранённые локации:

Route::get('/weather-locations', [WeatherLocationsController::class, 'index']);
Route::post('/weather-locations', [WeatherLocationsController::class, 'store']);
Route::delete('/weather-locations/{id}', [WeatherLocationsController::class, 'destroy']);

// Лидерборд:

Route::get('/leaderboard', [LeaderboardController::class, 'index']);

// Профиль — уловы/маркеры:

Route::get('/user/{id}/catches', [UserCatchesController::class, 'index']);
Route::get('/user/{id}/markers', [UserCatchesController::class, 'markers']);

    // карты/точки
    Route::get('/map/points',[PointsController::class,'index']);
    Route::get('/points/categories',[PointsController::class,'categories']);
    Route::post('/points',[PointsController::class,'store']);

    // загрузки/погода
    Route::post('/upload',[UploadController::class,'store']);
    Route::get('/weather',[WeatherProxyController::class,'show']);

    // лента/уловы
    Route::get('/feed',[FeedController::class,'index']);
    Route::get('/catch/{id}',[CatchController::class,'show']);
    Route::post('/catches',[CatchController::class,'store']);
    Route::get('/catches/markers',[CatchController::class,'markers']);

    // комменты/лайки/фоллоу
    Route::post('/catch/{id}/comments',[CommentController::class,'store']);
    Route::post('/catch/{id}/like',[LikeController::class,'toggle']);
    Route::post('/follow/{userId}',[FollowController::class,'toggle']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('points/me', [PointsController::class, 'me']);
        Route::get('points/ledger', [PointsController::class, 'ledger']);

        Route::get('referral/code', [ReferralController::class, 'myCode']);
        Route::post('referral/link', [ReferralController::class, 'link']); // body: {code}
    });

    // Карта
    Route::get('/map/points', [MapController::class, 'index']);
    Route::post('/map/points', [MapController::class, 'store']);            // если нужно
    Route::get('/map/points/{id}', [MapController::class, 'show']);

    // Уловы (минимум чтение для гостя)
    Route::get('/catches', [CatchesController::class, 'index']);
    Route::get('/catches/{id}', [CatchesController::class, 'show']);
    // Route::post('/catches', [CatchesController::class, 'store']);        // если уже включали

    // Загрузка медиа
    Route::post('/upload', [UploadController::class, 'store']);
});



