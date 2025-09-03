<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\FeedController;
use App\Http\Controllers\Api\V1\CatchController;
use App\Http\Controllers\Api\V1\MapController;
use App\Http\Middleware\ForceJsonResponse;

Route::middleware([ForceJsonResponse::class, 'throttle:api', \Fruitcake\Cors\HandleCors::class])->prefix('v1')->group(function () {

    Route::get('/feed', [FeedController::class, 'index']);

    Route::get('/map/icons', [MapController::class, 'icons']);
    Route::get('/map/points', [MapController::class, 'points']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/catches', [CatchController::class, 'store']);
    });
});
