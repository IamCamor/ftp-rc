<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        if (!Schema::hasTable('catch_comments')) {
            Schema::create('catch_comments', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('catch_id');
                $table->unsignedBigInteger('user_id')->nullable();
                $table->text('body');
                $table->boolean('is_approved')->default(true);
                $table->timestamps();
                $table->index(['catch_id']);
            });
        }
        if (!Schema::hasTable('catch_likes')) {
            Schema::create('catch_likes', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('catch_id');
                $table->unsignedBigInteger('user_id')->nullable();
                $table->timestamps();
                $table->unique(['catch_id','user_id']);
            });
        }
    }
    public function down(): void { Schema::dropIfExists('catch_comments'); Schema::dropIfExists('catch_likes'); }
};
