<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\AdminDashboardController;
use App\Http\Controllers\Admin\AdminUsersController;
use App\Http\Controllers\Admin\AdminPointsController;
use App\Http\Controllers\Admin\AdminCatchesController;
use App\Http\Controllers\Admin\AdminModerationController;
use App\Http\Controllers\Admin\AdminBannersController;
use App\Http\Controllers\Admin\AdminEventsController;
use App\Http\Controllers\Admin\AdminClubsController;

Route::middleware(['auth','can:admin'])->prefix('admin')->group(function () {
    Route::get('/', [AdminDashboardController::class, 'index'])->name('admin.dashboard');

    Route::get('/users', [AdminUsersController::class, 'index'])->name('admin.users');
    Route::post('/users/{id}/toggle-admin', [AdminUsersController::class, 'toggleAdmin'])->name('admin.users.toggleAdmin');

    Route::get('/points', [AdminPointsController::class, 'index'])->name('admin.points');
    Route::post('/points/{id}/feature', [AdminPointsController::class, 'feature'])->name('admin.points.feature');
    Route::delete('/points/{id}', [AdminPointsController::class, 'destroy'])->name('admin.points.destroy');

    Route::get('/catches', [AdminCatchesController::class, 'index'])->name('admin.catches');
    Route::delete('/catches/{id}', [AdminCatchesController::class, 'destroy'])->name('admin.catches.destroy');

    Route::get('/moderation', [AdminModerationController::class, 'index'])->name('admin.moderation');
    Route::post('/moderation/{id}/approve', [AdminModerationController::class, 'approve'])->name('admin.moderation.approve');
    Route::post('/moderation/{id}/reject',  [AdminModerationController::class, 'reject'])->name('admin.moderation.reject');

    Route::get('/banners', [AdminBannersController::class, 'index'])->name('admin.banners');
    Route::post('/banners/slot', [AdminBannersController::class, 'storeSlot'])->name('admin.banners.slot.store');
    Route::post('/banners', [AdminBannersController::class, 'storeBanner'])->name('admin.banners.store');
    Route::delete('/banners/{id}', [AdminBannersController::class, 'destroyBanner'])->name('admin.banners.destroy');

    Route::get('/events', [AdminEventsController::class, 'index'])->name('admin.events');
    Route::post('/events', [AdminEventsController::class, 'store'])->name('admin.events.store');
    Route::delete('/events/{id}', [AdminEventsController::class, 'destroy'])->name('admin.events.destroy');

    Route::get('/clubs', [AdminClubsController::class, 'index'])->name('admin.clubs');
    Route::delete('/clubs/{id}', [AdminClubsController::class, 'destroy'])->name('admin.clubs.destroy');
});
