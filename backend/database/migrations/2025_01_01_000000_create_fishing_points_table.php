<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        if (!Schema::hasTable('fishing_points')) {
            Schema::create('fishing_points', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->nullable();
                $table->double('lat'); $table->double('lng');
                $table->string('title'); $table->text('description')->nullable();
                $table->string('category', 32)->default('spot'); // shop/slip/resort/catch/spot
                $table->boolean('is_public')->default(true);
                $table->boolean('is_highlighted')->default(false);
                $table->string('status', 16)->default('approved'); // pending/approved
                $table->timestamps();
                $table->index(['category','is_public','is_highlighted']);
            });
        }
    }
    public function down(): void { Schema::dropIfExists('fishing_points'); }
};
