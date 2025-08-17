<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('catch_likes', function (Blueprint $t) {
      $t->id();
      $t->unsignedBigInteger('catch_id');
      $t->unsignedBigInteger('user_id');
      $t->timestamps();
      $t->unique(['catch_id','user_id']);
      $t->index('catch_id');
    });
  }
  public function down(): void { Schema::dropIfExists('catch_likes'); }
};