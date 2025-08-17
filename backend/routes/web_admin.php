<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminWebController;

Route::get('/admin', [AdminWebController::class, 'index']);
Route::get('/admin/comments', [AdminWebController::class, 'comments']);
Route::post('/admin/comments/{id}/approve', [AdminWebController::class, 'approveComment']);
Route::post('/admin/comments/{id}/reject', [AdminWebController::class, 'rejectComment']);
Route::get('/admin/points', [AdminWebController::class, 'points']);
Route::post('/admin/points/{id}/approve', [AdminWebController::class, 'approvePoint']);
Route::post('/admin/points/{id}/reject', [AdminWebController::class, 'rejectPoint']);
Route::get('/admin/users', [AdminWebController::class, 'users']);
Route::post('/admin/users/{id}/role', [AdminWebController::class, 'setRole']);
