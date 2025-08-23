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

Route::get('/health', fn()=>response()->json(['ok'=>true,'ts'=>now()]));

Route::prefix('v1')->group(function () {
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
});
