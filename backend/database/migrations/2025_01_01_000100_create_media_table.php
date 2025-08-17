<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('media', function (Blueprint $t) {
      $t->id();
      $t->string('model_type');
      $t->unsignedBigInteger('model_id');
      $t->string('disk')->default('public');
      $t->string('path');
      $t->string('mime')->nullable();
      $t->unsignedInteger('size')->nullable();
      $t->timestamps();
      $t->index(['model_type','model_id']);
    });
  }
  public function down(): void { Schema::dropIfExists('media'); }
};