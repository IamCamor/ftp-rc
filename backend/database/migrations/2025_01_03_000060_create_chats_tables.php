<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('chat_rooms', function (Blueprint $t){
      $t->id();
      $t->string('title')->nullable();
      $t->boolean('is_group')->default(false);
      $t->timestamps();
    });
    Schema::create('chat_room_users', function (Blueprint $t){
      $t->id();
      $t->unsignedBigInteger('room_id');
      $t->unsignedBigInteger('user_id');
      $t->timestamps();
      $t->unique(['room_id','user_id']);
      $t->index('user_id');
    });
    Schema::create('chat_messages', function (Blueprint $t){
      $t->id();
      $t->unsignedBigInteger('room_id');
      $t->unsignedBigInteger('user_id');
      $t->text('text');
      $t->timestamps();
      $t->index(['room_id','created_at']);
    });
  }
  public function down(): void {
    Schema::dropIfExists('chat_messages');
    Schema::dropIfExists('chat_room_users');
    Schema::dropIfExists('chat_rooms');
  }
};