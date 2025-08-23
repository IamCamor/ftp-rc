<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\{HealthController,UploadController,MapController,CatchesController,BonusController};
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\FeedController;

Route::get('/health',[HealthController::class,'ping']);

Route::prefix('v1')->group(function(){

Route::get('/feed', [FeedController::class, 'index']);                  // публичная лента
Route::get('/feed/{id}/comments', [FeedController::class, 'comments']); // публичные комменты к улову

// действия, когда подключишь авторизацию (Sanctum/JWT):
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/feed/{id}/like', [FeedController::class, 'like']);
    Route::delete('/feed/{id}/like', [FeedController::class, 'unlike']);
    Route::post('/feed/{id}/comments', [FeedController::class, 'addComment']);
});
  // загрузка фото
  Route::post('/upload/image',[UploadController::class,'image']);

  // карта/точки
  Route::get('/map/points', [MapController::class, 'index']);
  Route::post('/map/points', [MapController::class, 'store']);
  Route::get('/map/points/{id}', [MapController::class, 'show']);
  Route::match(['put','patch'], '/v1/map/points/{id}', [MapController::class, 'update']);
  Route::delete('/map/points/{id}', [MapController::class, 'destroy']);
  Route::get('/map/categories', [MapController::class, 'categories']);
  Route::get('/map/points/list', [MapController::class, 'list']);

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





// --- WRITE ENDPOINTS (create catch/place) ---
use App\Http\Controllers\Api\CatchWriteController;
use App\Http\Controllers\Api\PointWriteController;

Route::prefix('v1')->group(function () {
    Route::post('/catches', [CatchWriteController::class,'store']); // POST /api/v1/catches
    Route::post('/points',  [PointWriteController::class,'store']); // POST /api/v1/points
    Route::get('/points/categories', [PointWriteController::class,'categories']); // справочник
});
