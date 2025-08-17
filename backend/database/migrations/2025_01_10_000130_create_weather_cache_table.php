<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('weather_cache', function (Blueprint $t){
      $t->id();
      $t->string('key')->unique();
      $t->json('current')->nullable();
      $t->json('daily')->nullable();
      $t->dateTime('fetched_at');
      $t->timestamps();
    });
  }
  public function down(): void { Schema::dropIfExists('weather_cache'); }
};