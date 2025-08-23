<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        // Регистрация наблюдателей,
        // только если модели существуют в проекте:
        if (class_exists(\App\Models\CatchRecord::class) && class_exists(\App\Observers\CatchRecordObserver::class)) {
            \App\Models\CatchRecord::observe(\App\Observers\CatchRecordObserver::class);
        }
        if (class_exists(\App\Models\FishingPoint::class) && class_exists(\App\Observers\FishingPointObserver::class)) {
            \App\Models\FishingPoint::observe(\App\Observers\FishingPointObserver::class);
        }
    }
}
