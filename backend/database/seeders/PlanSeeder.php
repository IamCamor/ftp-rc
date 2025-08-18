<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Plan;

class PlanSeeder extends Seeder
{
    public function run(): void
    {
        Plan::updateOrCreate(['code' => 'pro_month'], [
            'title' => 'Pro Месяц',
            'price' => 299,
            'currency' => 'RUB',
            'interval' => 'month',
            'features' => ['Карты','Фильтры','Pro-бейдж']
        ]);
        Plan::updateOrCreate(['code' => 'pro_year'], [
            'title' => 'Pro Год',
            'price' => 2490,
            'currency' => 'RUB',
            'interval' => 'year',
            'features' => ['Экономия 20%']
        ]);
    }
}
