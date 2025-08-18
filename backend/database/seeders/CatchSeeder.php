<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\CatchRecord;

class CatchSeeder extends Seeder
{
    public function run(): void
    {
        for ($i=1; $i<=100; $i++) {
            CatchRecord::create([
                'lat' => 55.75 + (mt_rand(-300,300)/1000.0),
                'lng' => 37.62 + (mt_rand(-500,500)/1000.0),
                'species' => 'Щука',
                'length' => mt_rand(20, 120),
                'weight' => mt_rand(1, 12),
                'depth' => mt_rand(1, 15),
                'style' => 'берег',
                'lure' => 'Воблер',
                'tackle' => 'Спиннинг',
                'privacy' => 'all',
                'companions' => 'Иван, Пётр',
                'notes' => 'Демо-запись',
                'caught_at' => now()->subDays(mt_rand(0,90)),
            ]);
        }
    }
}
