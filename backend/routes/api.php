<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\{HealthController,UploadController,MapController,CatchesController,BonusController};
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;

Route::get('/health',[HealthController::class,'ping']);

Route::prefix('v1')->group(function(){
  // загрузка фото
  Route::post('/upload/image',[UploadController::class,'image']);

  // карта/точки
  Route::get('/v1/map/points', [MapController::class, 'index']);
  Route::post('/v1/map/points', [MapController::class, 'store']);
  Route::get('/v1/map/points/{id}', [MapController::class, 'show']);
  Route::match(['put','patch'], '/v1/map/points/{id}', [MapController::class, 'update']);
  Route::delete('/v1/map/points/{id}', [MapController::class, 'destroy']);
  Route::get('/v1/map/categories', [MapController::class, 'categories']);
  Route::get('/v1/map/points/list', [MapController::class, 'list']);

  // уловы
  Route::get('/catches',[CatchesController::class,'index']);
  Route::post('/catches',[CatchesController::class,'store']);
  Route::get('/catches/{id}',[CatchesController::class,'show']);
  Route::put('/catches/{id}',[CatchesController::class,'update']);
  Route::delete('/catches/{id}',[CatchesController::class,'destroy']);

  Route::post('/login',    [AuthController::class, 'login']);
  Route::post('/register', [AuthController::class, 'register']);
  Route::post('/logout',   [AuthController::class, 'logout'])->middleware('auth:sanctum');
  Route::get('/me',        [AuthController::class, 'me'])->middleware('auth:sanctum');

    // Профиль
  Route::get('/profile/handle-available', [ProfileController::class, 'handleAvailable']);
  Route::post('/profile/setup',           [ProfileController::class, 'setup'])->middleware('auth:sanctum');
  Route::post('/profile/avatar',          [ProfileController::class, 'uploadAvatar'])->middleware('auth:sanctum');

});

/* === Bonus System Routes (auto-insert) === */
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/bonus/me', [BonusController::class, 'me']);
    Route::get('/bonus/history', [BonusController::class, 'history']);
    Route::post('/bonus/redeem-pro', [BonusController::class, 'redeemPro']);
});
/* === /Bonus System Routes === */

