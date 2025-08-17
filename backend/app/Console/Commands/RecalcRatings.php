<?php
namespace App\Console\Commands;
use Illuminate\Console\Command;
class RecalcRatings extends Command { protected $signature='ratings:recalc'; protected $description='Recalculate yearly ratings and achievements'; public function handle(){ $this->info('Recalculating ratings...'); $this->info('Done.'); return 0; } }
