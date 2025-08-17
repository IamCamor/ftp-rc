<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('weather_cache')) {
            Schema::create('weather_cache', function (Blueprint $table) {
                $table->id();
                $table->string('key');
                $table->text('current')->nullable();
                $table->text('daily')->nullable();
                $table->dateTime('fetched_at');
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('weather_cache')) {
            Schema::dropIfExists('weather_cache');
        }
    }
};
