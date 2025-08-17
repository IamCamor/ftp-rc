<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\PaymentsController;
use App\Http\Controllers\Api\Webhooks\StripeWebhookController;
use App\Http\Controllers\Api\Webhooks\YookassaWebhookController;

Route::get('/plans', [PaymentsController::class, 'plans']);
Route::post('/create-checkout', [PaymentsController::class, 'createCheckout']);
Route::post('/highlight-point', [PaymentsController::class, 'highlightPoint']);
Route::get('/subscription', [PaymentsController::class, 'subscriptionStatus']);
Route::post('/subscription/cancel', [PaymentsController::class, 'cancelSubscription']);

Route::post('/webhooks/stripe', [StripeWebhookController::class, 'handle']);
Route::post('/webhooks/yookassa', [YookassaWebhookController::class, 'handle']);
