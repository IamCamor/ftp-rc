<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\BillingController;
use App\Http\Controllers\Api\BannersController;
use App\Http\Controllers\Api\SearchController;
use App\Http\Controllers\Api\WeatherController;
Route::middleware('auth:sanctum')->group(function(){ Route::post('/billing/payment',[BillingController::class,'createPayment']); Route::get('/billing/subscription',[BillingController::class,'mySubscription']); Route::post('/billing/subscription/cancel',[BillingController::class,'cancel']); });
Route::post('/billing/webhook/{provider}',[BillingController::class,'webhook']);
Route::get('/banners/slots',[BannersController::class,'slots']);
Route::get('/banners/slot/{code}',[BannersController::class,'listForSlot']);
Route::post('/banners/{id}/impression',[BannersController::class,'impression'])->middleware('throttle:60,1');
Route::get('/search',[SearchController::class,'global']);
Route::get('/weather',[WeatherController::class,'current']);
