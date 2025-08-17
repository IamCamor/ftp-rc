<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class RenewSubscriptionsCommand extends Command
{
    protected $signature = 'ftp:renew-subs';
    protected $description = 'Renew subscriptions (demo stub)';
    public function handle(): int
    {
        DB::table('subscriptions')->update(['renews_at'=>now()->addMonth()]);
        $this->info('Subscriptions renewed (demo)');
        return self::SUCCESS;
    }
}
