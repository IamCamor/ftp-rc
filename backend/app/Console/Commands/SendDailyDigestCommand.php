<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class SendDailyDigestCommand extends Command
{
    protected $signature = 'ftp:digest';
    protected $description = 'Send daily email digest (demo stub)';
    public function handle(): int
    {
        Log::info('Daily digest sent (demo)');
        $this->info('Daily digest: OK');
        return self::SUCCESS;
    }
}
