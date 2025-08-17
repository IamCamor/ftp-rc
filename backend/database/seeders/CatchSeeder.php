<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CatchSeeder extends Seeder
{
    public function run(): void
    {
        if (DB::table('catch_records')->count() >= 50) return;
        $species = ['Щука','Окунь','Судак','Лещ','Карп','Форель'];
        for ($i=1; $i<=120; $i++) {
            $sp = $species[array_rand($species)];
            DB::table('catch_records')->insert([
                'user_id'=>rand(1,20),
                'lat'=>55.5 + mt_rand(-30000,30000)/1e6,
                'lng'=>37.5 + mt_rand(-30000,30000)/1e6,
                'species'=>$sp,
                'length'=>mt_rand(20,100),
                'weight'=>mt_rand(1,80)/10,
                'depth'=>mt_rand(1,15),
                'style'=>['берег','лодка','лёд'][array_rand(['берег','лодка','лёд'])],
                'lure'=>['воблер','джиг','блесна','мормышка'][array_rand(['воблер','джиг','блесна','мормышка'])],
                'tackle'=>'комбо',
                'privacy'=>'all',
                'caught_at'=>now()->subDays(rand(0,60)),
                'photo_url'=>null,
                'created_at'=>now()->subDays(rand(0,60)), 'updated_at'=>now()
            ]);
        }
    }
}
