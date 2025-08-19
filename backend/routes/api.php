<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\FishingLogController;
use App\Http\Controllers\FishingPointController;
use App\Http\Controllers\EventController;
use App\Http\Controllers\ClubController;
use App\Http\Controllers\BlogController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\MapController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// s1 – healthcheck
Route::get('/health', fn () => response()->json(['status' => 'ok']));

// s2 – аутентификация
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

// s3 – профиль
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
});

// s4 – дневник рыбалок
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/logs', [FishingLogController::class, 'index']);
    Route::post('/logs', [FishingLogController::class, 'store']);
    Route::get('/logs/{id}', [FishingLogController::class, 'show']);
    Route::put('/logs/{id}', [FishingLogController::class, 'update']);
    Route::delete('/logs/{id}', [FishingLogController::class, 'destroy']);
});

// s5 – карта точек
Route::get('/map/points', [FishingPointController::class, 'index']);
Route::middleware('auth:sanctum')->post('/map/points', [FishingPointController::class, 'store']);
Route::get('/map/points/{id}', [FishingPointController::class, 'show']);
Route::middleware('auth:sanctum')->put('/map/points/{id}', [FishingPointController::class, 'update']);
Route::middleware('auth:sanctum')->delete('/map/points/{id}', [FishingPointController::class, 'destroy']);

// s6 – события
Route::get('/events', [EventController::class, 'index']);
Route::get('/events/{id}', [EventController::class, 'show']);
Route::middleware('auth:sanctum')->post('/events', [EventController::class, 'store']);
Route::middleware('auth:sanctum')->put('/events/{id}', [EventController::class, 'update']);
Route::middleware('auth:sanctum')->delete('/events/{id}', [EventController::class, 'destroy']);

// s7 – клубы
Route::get('/clubs', [ClubController::class, 'index']);
Route::get('/clubs/{id}', [ClubController::class, 'show']);
Route::middleware('auth:sanctum')->post('/clubs', [ClubController::class, 'store']);
Route::middleware('auth:sanctum')->put('/clubs/{id}', [ClubController::class, 'update']);
Route::middleware('auth:sanctum')->delete('/clubs/{id}', [ClubController::class, 'destroy']);

// s8 – блог
Route::get('/blogs', [BlogController::class, 'index']);
Route::get('/blogs/{id}', [BlogController::class, 'show']);
Route::middleware('auth:sanctum')->post('/blogs', [BlogController::class, 'store']);
Route::middleware('auth:sanctum')->put('/blogs/{id}', [BlogController::class, 'update']);
Route::middleware('auth:sanctum')->delete('/blogs/{id}', [BlogController::class, 'destroy']);

// s9 – админка (moderation, рассылки, управление пользователями)
Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::get('/admin/users', [AdminController::class, 'users']);
    Route::put('/admin/users/{id}/block', [AdminController::class, 'blockUser']);
    Route::post('/admin/notifications', [AdminController::class, 'sendNotification']);
});

// s10 – платежи
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/payments/create', [PaymentController::class, 'create']);
    Route::post('/payments/webhook/stripe', [PaymentController::class, 'webhookStripe']);
    Route::post('/payments/webhook/yookassa', [PaymentController::class, 'webhookYooKassa']);
});

// s11 – расширения карты (магазины, базы отдыха и т.д.)
Route::get('/map/objects', [MapController::class, 'objects']);
Route::middleware('auth:sanctum')->post('/map/objects', [MapController::class, 'store']);
Route::middleware('auth:sanctum')->put('/map/objects/{id}', [MapController::class, 'update']);
Route::middleware('auth:sanctum')->delete('/map/objects/{id}', [MapController::class, 'destroy']);

// s12 – комментарии и чаты
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logs/{id}/comments', [FishingLogController::class, 'addComment']);
    Route::get('/logs/{id}/comments', [FishingLogController::class, 'comments']);
    Route::post('/chats', [ProfileController::class, 'createChat']);
    Route::get('/chats/{id}', [ProfileController::class, 'chatMessages']);
    Route::post('/chats/{id}/messages', [ProfileController::class, 'sendMessage']);
});
