<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\{HealthController,UploadController,MapController,CatchesController};

Route::get('/health',[HealthController::class,'ping']);

Route::prefix('v1')->group(function(){
  // загрузка фото
  Route::post('/upload/image',[UploadController::class,'image']);

  // карта/точки
  Route::get('/map/points',[MapController::class,'index']);
  Route::post('/map/points',[MapController::class,'store']);
  Route::get('/map/points/{id}',[MapController::class,'show']);
  Route::put('/map/points/{id}',[MapController::class,'update']);
  Route::delete('/map/points/{id}',[MapController::class,'destroy']);
  Route::get('/map/categories',[MapController::class,'categories']);
  Route::get('/map/list',[MapController::class,'list']);

  // уловы
  Route::get('/catches',[CatchesController::class,'index']);
  Route::post('/catches',[CatchesController::class,'store']);
  Route::get('/catches/{id}',[CatchesController::class,'show']);
  Route::put('/catches/{id}',[CatchesController::class,'update']);
  Route::delete('/catches/{id}',[CatchesController::class,'destroy']);
});
