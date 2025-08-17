<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ConfigController;
Route::get('/config/ui', [ConfigController::class, 'ui']);
