<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\PublicApiController;

Route::prefix('public')->group(function () {
    Route::get('/users/{slug}', [PublicApiController::class, 'user']);
    Route::get('/catches/{id}', [PublicApiController::class, 'catch']);
});
