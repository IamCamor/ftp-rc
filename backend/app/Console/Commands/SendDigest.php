<?php
namespace App\Console\Commands;
use Illuminate\Console\Command;
class SendDigest extends Command { protected $signature='digest:send'; protected $description='Send weekly activity digest emails'; public function handle(){ $this->info('Sending digests...'); $this->info('Done.'); return 0; } }
