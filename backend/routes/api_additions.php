<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ModerationController;
Route::middleware('auth:sanctum')->group(function () {
  Route::post('/moderation/submit', [ModerationController::class, 'submit']);
  Route::get('/moderation', [ModerationController::class, 'list']);
  Route::post('/moderation/{id}/decide', [ModerationController::class, 'decide'])->middleware('admin');
});
