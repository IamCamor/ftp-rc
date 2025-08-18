<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\NotificationsController as NC;

Route::prefix('notifications')->group(function(){
    Route::get('/', [NC::class, 'index']);                 // ?type=like|comment|friend|system
    Route::post('/create-test', [NC::class, 'createTest']); // body: { user_id?, type? }
    Route::post('/{id}/read', [NC::class, 'markRead']);
    Route::post('/read-all', [NC::class, 'markAllRead']);   // ?user_id=
    Route::get('/settings', [NC::class, 'settingsGet']);     // ?user_id=
    Route::post('/settings', [NC::class, 'settingsSave']);   // body + user_id
});
