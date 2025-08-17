<?php
// routes/api.php (фрагменты для вставки)
Route::middleware('auth:sanctum')->group(function(){
  Route::post('/catches/{id}/media', [\App\Http\Controllers\Api\CatchesController::class, 'uploadMedia']);
  Route::post('/feed/{id}/like', [\App\Http\Controllers\Api\CatchesController::class, 'like']);
  Route::post('/feed/{id}/unlike', [\App\Http\Controllers\Api\CatchesController::class, 'unlike']);
  Route::post('/feed/{id}/comment', [\App\Http\Controllers\Api\CatchesController::class, 'comment']);
});
Route::get('/feed/global', [\App\Http\Controllers\Api\FeedController::class, 'global']);
Route::get('/feed/local',  [\App\Http\Controllers\Api\FeedController::class, 'local']);
Route::get('/feed/follow', [\App\Http\Controllers\Api\FeedController::class, 'follow']);
Route::middleware(['auth:sanctum','can:admin'])->group(function(){
  Route::get('/admin/moderation', [\App\Http\Controllers\Api\ModerationController::class, 'index']);
  Route::post('/admin/moderation/{id}/approve', [\App\Http\Controllers\Api\ModerationController::class, 'approve']);
  Route::post('/admin/moderation/{id}/reject',  [\App\Http\Controllers\Api\ModerationController::class, 'reject']);
});