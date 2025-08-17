<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class StoresSeeder extends Seeder
{
    public function run(): void
    {
        if (DB::table('stores')->count() >= 50) return;
        for ($i=1; $i<=120; $i++) {
            DB::table('stores')->insert([
                'name'=>"Магазин снастей #{$i}",
                'address'=>"Город, Улица {$i}",
                'lat'=>55.6 + mt_rand(-15000,15000)/1e6,
                'lng'=>37.6 + mt_rand(-15000,15000)/1e6,
                'url'=>'https://example.com/store',
                'category'=>'tackle',
                'created_at'=>now(), 'updated_at'=>now()
            ]);
        }
    }
}
