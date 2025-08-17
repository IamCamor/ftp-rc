<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            UsersSeeder::class,
            ClubsSeeder::class,
            EventsSeeder::class,
            StoresSeeder::class,
            PlaceSeeder::class,
            CatchSeeder::class,
            NotificationsSeeder::class,
            ChatsSeeder::class,
            S8SlugSeeder::class,
        ]);
    }
}
