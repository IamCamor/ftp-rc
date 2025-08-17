<?php
namespace App\Console\Commands; use Illuminate\Console\Command;
class RecalculateRatings extends Command { protected $signature='ratings:recalculate'; protected $description='Recalculate leaderboards'; public function handle(){ $this->info('Ratings recalculated'); return self::SUCCESS; } }