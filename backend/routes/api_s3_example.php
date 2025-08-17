<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\FriendsController;
use App\Http\Controllers\Api\ClubsController;
use App\Http\Controllers\Api\EventsController;
use App\Http\Controllers\Api\NotificationsController;
use App\Http\Controllers\Api\ChatsController;

Route::middleware('auth:sanctum')->group(function(){
  Route::get('/friends', [FriendsController::class,'index']);
  Route::post('/friends/request', [FriendsController::class,'request']);
  Route::post('/friends/{id}/accept', [FriendsController::class,'accept']);
  Route::post('/friends/{id}/decline', [FriendsController::class,'decline']);
});

Route::get('/clubs', [ClubsController::class,'index']);
Route::middleware('auth:sanctum')->group(function(){
  Route::post('/clubs', [ClubsController::class,'store']);
  Route::get('/clubs/{id}', [ClubsController::class,'show']);
  Route::post('/clubs/{id}/join', [ClubsController::class,'join']);
  Route::post('/clubs/{id}/leave', [ClubsController::class,'leave']);
});

Route::get('/events', [EventsController::class,'index']);
Route::middleware('auth:sanctum')->group(function(){
  Route::post('/events', [EventsController::class,'store']);
  Route::post('/events/{id}/subscribe', [EventsController::class,'subscribe']);
  Route::post('/events/{id}/unsubscribe', [EventsController::class,'unsubscribe']);
});

Route::middleware('auth:sanctum')->group(function(){
  Route::get('/notifications', [NotificationsController::class,'index']);
  Route::post('/notifications/{id}/read', [NotificationsController::class,'markRead']);
});

Route::middleware('auth:sanctum')->group(function(){
  Route::get('/chats', [ChatsController::class,'rooms']);
  Route::get('/chats/{roomId}/messages', [ChatsController::class,'messages']);
  Route::post('/chats/{roomId}/send', [ChatsController::class,'send']);
});
