<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

// Явное объявление команд S3 (можно опустить, если автодискавер включен)
use App\Console\Commands\RecalcRatings;
use App\Console\Commands\SendDigest;
use App\Console\Commands\RenewSubscriptions;

class Kernel extends ConsoleKernel
{
    /**
     * Если хочешь — можно явно зарегистрировать команды:
     */
    protected $commands = [
        RecalcRatings::class,
        SendDigest::class,
        RenewSubscriptions::class,
    ];

    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // Пересчёт рейтингов/ачивок
        $schedule->command('ratings:recalc')->dailyAt('03:10');

        // Еженедельный дайджест (понедельник 08:00)
        $schedule->command('digest:send')->weeklyOn(1, '08:00');

        // Продление подписок (каждый день 04:00)
        $schedule->command('subscriptions:renew')->dailyAt('04:00');

        // Пример: очистка кэшей/логов (по желанию)
        // $schedule->command('queue:prune-batches --hours=48')->daily();
        // $schedule->command('model:prune')->daily();
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
