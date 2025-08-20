<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\{
  HealthController, MapController, CatchesController, EventsController, FeedController, ClubsController
};

Route::get('/health',[HealthController::class,'ping']);

Route::prefix('v1')->group(function(){
  // Map (публично)
  Route::get('/map/points',[MapController::class,'index']);
  Route::post('/map/points',[MapController::class,'store']);
  Route::get('/map/points/{id}',[MapController::class,'show']);
  Route::put('/map/points/{id}',[MapController::class,'update']);
  Route::delete('/map/points/{id}',[MapController::class,'destroy']);
  Route::get('/map/categories',[MapController::class,'categories']);
  Route::get('/map/list',[MapController::class,'list']);

  // Catches (публичная лента по privacy=all)
  Route::get('/catches',[CatchesController::class,'index']);
  Route::post('/catches',[CatchesController::class,'store']);
  Route::get('/catches/{id}',[CatchesController::class,'show']);
  Route::put('/catches/{id}',[CatchesController::class,'update']);
  Route::delete('/catches/{id}',[CatchesController::class,'destroy']);

  // Events & Clubs (публично)
  Route::get('/events',[EventsController::class,'index']);
  Route::post('/events',[EventsController::class,'store']);
  Route::get('/events/{id}',[EventsController::class,'show']);
  Route::put('/events/{id}',[EventsController::class,'update']);
  Route::delete('/events/{id}',[EventsController::class,'destroy']);
  Route::get('/clubs/{clubId}/events',[EventsController::class,'byClub']);

  Route::get('/clubs',[ClubsController::class,'index']);
  Route::post('/clubs',[ClubsController::class,'store']);
  Route::get('/clubs/{id}',[ClubsController::class,'show']);
  Route::put('/clubs/{id}',[ClubsController::class,'update']);
  Route::delete('/clubs/{id}',[ClubsController::class,'destroy']);

  // Feed (публично)
  Route::get('/feed/global',[FeedController::class,'global']);
  Route::get('/feed/local',[FeedController::class,'local']);
  Route::get('/feed/follow',[FeedController::class,'follow']);
});
