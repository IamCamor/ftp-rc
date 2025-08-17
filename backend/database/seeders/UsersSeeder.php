<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class UsersSeeder extends Seeder
{
    public function run(): void
    {
        if (DB::table('users')->count() >= 10) return;
        for ($i=1; $i<=20; $i++) {
            $name = "Рыбак {$i}";
            DB::table('users')->insert([
                'name'=>$name,
                'email'=>"user{$i}@example.com",
                'password'=>bcrypt('password'),
                'slug'=>Str::slug($name)."-{$i}",
                'created_at'=>now(), 'updated_at'=>now()
            ]);
        }
    }
}
