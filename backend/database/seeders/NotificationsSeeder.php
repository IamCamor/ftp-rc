<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class NotificationsSeeder extends Seeder
{
    public function run(): void
    {
        if (DB::table('notifications')->count() >= 50) return;
        $types = ['like','comment','friend_request','achievement','reminder'];
        for ($i=1; $i<=120; $i++) {
            DB::table('notifications')->insert([
                'user_id'=>1,
                'type'=>$types[array_rand($types)],
                'data'=>json_encode(['message'=>"Событие #{$i}"], JSON_UNESCAPED_UNICODE),
                'created_at'=>now()->subDays(rand(0,30)), 'updated_at'=>now()
            ]);
        }
    }
}
