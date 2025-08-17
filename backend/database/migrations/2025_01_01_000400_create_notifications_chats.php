<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        if (!Schema::hasTable('notifications')) {
            Schema::create('notifications', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->string('type',64);
                $table->json('data')->nullable();
                $table->timestamp('read_at')->nullable();
                $table->timestamps();
                $table->index(['user_id','type']);
            });
        }
        if (!Schema::hasTable('chats')) {
            Schema::create('chats', function (Blueprint $table) {
                $table->id();
                $table->string('name')->nullable(); // null = direct chat
                $table->timestamps();
            });
        }
        if (!Schema::hasTable('chat_messages')) {
            Schema::create('chat_messages', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('chat_id');
                $table->unsignedBigInteger('user_id')->nullable();
                $table->text('body');
                $table->boolean('is_approved')->default(true);
                $table->timestamps();
                $table->index(['chat_id']);
            });
        }
    }
    public function down(): void { Schema::dropIfExists('notifications'); Schema::dropIfExists('chat_messages'); Schema::dropIfExists('chats'); }
};
