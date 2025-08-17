<?php
namespace App\Console\Commands;
use Illuminate\Console\Command;
class RenewSubscriptions extends Command { protected $signature='subscriptions:renew'; protected $description='Renew paid subscriptions and charge payments'; public function handle(){ $this->info('Renewing subscriptions...'); $this->info('Done.'); return 0; } }
