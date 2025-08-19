<?php
namespace App\Console;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;
class Kernel extends ConsoleKernel {
  protected function schedule(Schedule $s): void {
    $s->call(fn()=>\Log::info('daily_digest'))->dailyAt('08:00');
    $s->call(fn()=>\Log::info('recalculate_ratings'))->hourly();
    $s->call(fn()=>\Log::info('renew_subscriptions'))->dailyAt('03:00');
  }
  protected function commands(): void { $this->load(__DIR__.'/Commands'); require base_path('routes/console.php'); }
}
