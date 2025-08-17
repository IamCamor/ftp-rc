<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\Admin\AdminCommentsController;
use App\Http\Controllers\Api\Admin\AdminPointsController;
use App\Http\Controllers\Api\Admin\AdminUsersController;

Route::middleware([])->prefix('admin')->group(function () {
    Route::get('/comments/pending', [AdminCommentsController::class, 'pending']);
    Route::post('/comments/{id}/approve', [AdminCommentsController::class, 'approve']);
    Route::post('/comments/{id}/reject', [AdminCommentsController::class, 'reject']);

    Route::get('/points/pending', [AdminPointsController::class, 'pending']);
    Route::post('/points/{id}/approve', [AdminPointsController::class, 'approve']);
    Route::post('/points/{id}/reject', [AdminPointsController::class, 'reject']);

    Route::get('/users', [AdminUsersController::class, 'index']);
    Route::post('/users/{id}/role', [AdminUsersController::class, 'setRole']);
});
