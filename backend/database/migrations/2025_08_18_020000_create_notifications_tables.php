<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('notifications', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('user_id')->default(0);
            $table->string('type', 50); // like, comment, friend, system
            $table->text('title')->nullable();
            $table->text('body')->nullable();
            $table->json('meta')->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamps();
            $table->index(['user_id','type','is_read']);
        });

        Schema::create('notification_settings', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('user_id')->unique();
            $table->boolean('email_likes')->default(true);
            $table->boolean('email_comments')->default(true);
            $table->boolean('email_friends')->default(true);
            $table->boolean('email_system')->default(true);
            $table->boolean('push_likes')->default(true);
            $table->boolean('push_comments')->default(true);
            $table->boolean('push_friends')->default(true);
            $table->boolean('push_system')->default(true);
            $table->timestamps();
        });
    }
    public function down(): void
    {
        Schema::dropIfExists('notification_settings');
        Schema::dropIfExists('notifications');
    }
};
