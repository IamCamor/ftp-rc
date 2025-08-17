<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Точно существующие сидеры
        if (class_exists(\Database\Seeders\UserSeeder::class)) {
            $this->call(\Database\Seeders\UserSeeder::class);
        }

        if (class_exists(\Database\Seeders\S3DemoSeeder::class)) {
            $this->call(\Database\Seeders\S3DemoSeeder::class);
        }
    }
}
