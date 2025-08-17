<?php
// Вставь в routes/api.php рядом с другими публичными маршрутами S4:
use App\Http\Controllers\Api\WeatherController;
Route::get('/weather', [WeatherController::class, 'index']); // lat,lng,lang,units
