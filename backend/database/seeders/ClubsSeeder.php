<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ClubsSeeder extends Seeder
{
    public function run(): void
    {
        if (DB::table('clubs')->count() >= 50) return;
        for ($i=1; $i<=120; $i++) {
            DB::table('clubs')->insert([
                'name'=>"Клуб Рыболовов #{$i}",
                'logo_url'=>null,
                'region'=>'RU-MOW',
                'members_count'=>rand(10,500),
                'description'=>'Сообщество увлечённых рыбалкой (демо)',
                'created_at'=>now(), 'updated_at'=>now()
            ]);
        }
    }
}
