<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        if (!Schema::hasTable('catch_records')) {
            Schema::create('catch_records', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->nullable();
                $table->double('lat'); $table->double('lng');
                $table->string('species')->nullable();
                $table->float('length')->nullable(); $table->float('weight')->nullable(); $table->float('depth')->nullable();
                $table->string('style')->nullable(); $table->string('lure')->nullable(); $table->string('tackle')->nullable();
                $table->string('privacy', 16)->default('all');
                $table->dateTime('caught_at')->nullable();
                $table->string('water_type')->nullable(); $table->float('water_temp')->nullable();
                $table->float('wind_speed')->nullable(); $table->float('pressure')->nullable();
                $table->string('companions')->nullable(); $table->text('notes')->nullable();
                $table->string('photo_url')->nullable();
                $table->timestamps();
                $table->index(['user_id','species']);
            });
        }
    }
    public function down(): void { Schema::dropIfExists('catch_records'); }
};
