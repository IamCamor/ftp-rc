<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ChatsSeeder extends Seeder
{
    public function run(): void
    {
        if (DB::table('chats')->count() >= 10) return;
        for ($i=1; $i<=20; $i++) {
            $cid = DB::table('chats')->insertGetId(['name'=>"Чат #{$i}", 'created_at'=>now(), 'updated_at'=>now() ]);
            for ($m=1; $m<=10; $m++) {
                DB::table('chat_messages')->insert([
                    'chat_id'=>$cid, 'user_id'=>rand(1,20), 'body'=>"Сообщение {$m} в чате #{$i}",
                    'is_approved'=>true, 'created_at'=>now(), 'updated_at'=>now()
                ]);
            }
        }
    }
}
