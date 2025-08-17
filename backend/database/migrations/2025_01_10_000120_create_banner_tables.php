<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('banner_slots', function (Blueprint $t){
      $t->id();
      $t->string('code')->unique();
      $t->string('title');
      $t->timestamps();
    });
    Schema::create('banners', function (Blueprint $t){
      $t->id();
      $t->unsignedBigInteger('slot_id');
      $t->string('name');
      $t->string('image')->nullable();
      $t->string('url')->nullable();
      $t->boolean('is_active')->default(true);
      $t->unsignedInteger('priority')->default(100);
      $t->timestamps();
      $t->index(['slot_id','is_active']);
    });
    Schema::create('banner_impressions', function (Blueprint $t){
      $t->id();
      $t->unsignedBigInteger('banner_id');
      $t->unsignedBigInteger('user_id')->nullable();
      $t->string('session')->nullable();
      $t->string('ip')->nullable();
      $t->timestamps();
      $t->index(['banner_id','created_at']);
    });
  }
  public function down(): void {
    Schema::dropIfExists('banner_impressions');
    Schema::dropIfExists('banners');
    Schema::dropIfExists('banner_slots');
  }
};