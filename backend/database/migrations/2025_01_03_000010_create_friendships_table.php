<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('friendships', function (Blueprint $t){
      $t->id();
      $t->unsignedBigInteger('user_id');
      $t->unsignedBigInteger('friend_id');
      $t->enum('status', ['pending','accepted','declined','blocked'])->default('pending');
      $t->timestamps();
      $t->unique(['user_id','friend_id']);
      $t->index(['friend_id']);
    });
  }
  public function down(): void { Schema::dropIfExists('friendships'); }
};