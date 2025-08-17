<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('notifications', function (Blueprint $t){
      $t->id();
      $t->unsignedBigInteger('user_id');
      $t->string('type');
      $t->json('data')->nullable();
      $t->boolean('is_read')->default(false);
      $t->timestamps();
      $t->index(['user_id','is_read','type']);
    });
  }
  public function down(): void { Schema::dropIfExists('notifications'); }
};