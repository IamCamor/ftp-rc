<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class PlaceSeeder extends Seeder
{
    public function run(): void
    {
        if (DB::table('fishing_points')->count() >= 50) return;
        $cats = ['spot','shop','slip','resort'];
        for ($i=1; $i<=120; $i++) {
            DB::table('fishing_points')->insert([
                'user_id'=>rand(1,20),
                'lat'=>55.0 + mt_rand(-50000,50000)/1e6,
                'lng'=>37.0 + mt_rand(-50000,50000)/1e6,
                'title'=>"Локация #{$i}",
                'description'=>'Демо точка для теста карты',
                'category'=>$cats[array_rand($cats)],
                'is_public'=>true,
                'is_highlighted'=> (rand(1,20)===1),
                'status'=>'approved',
                'created_at'=>now(), 'updated_at'=>now()
            ]);
        }
    }
}
