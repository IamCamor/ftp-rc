<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class EventsSeeder extends Seeder
{
    public function run(): void
    {
        if (DB::table('events')->count() >= 50) return;
        for ($i=1; $i<=120; $i++) {
            DB::table('events')->insert([
                'title'=>"Турнир #{$i}",
                'region'=>'RU-MOW',
                'starts_at'=>now()->addDays(rand(1,120)),
                'ends_at'=>now()->addDays(rand(1,120))->addHours(6),
                'description'=>'Соревнования по рыбалке (демо)',
                'location_lat'=>55.7 + mt_rand(-20000,20000)/1e6,
                'location_lng'=>37.6 + mt_rand(-20000,20000)/1e6,
                'link'=>'https://example.com/event',
                'org_club_id'=>rand(1,50),
                'created_at'=>now(), 'updated_at'=>now(),
            ]);
        }
    }
}
