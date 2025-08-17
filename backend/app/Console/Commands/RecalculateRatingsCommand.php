<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class RecalculateRatingsCommand extends Command
{
    protected $signature = 'ftp:recalc-ratings';
    protected $description = 'Recalculate rankings/achievements (demo)';
    public function handle(): int
    {
        // Demo: just count catches per user
        $counts = DB::table('catch_records')->select('user_id', DB::raw('count(*) as c'))->groupBy('user_id')->get();
        $this->info('Ratings recalculated for '.count($counts).' users');
        return self::SUCCESS;
    }
}
