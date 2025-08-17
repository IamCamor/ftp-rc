<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('moderation_queue', function (Blueprint $t) {
      $t->id();
      $t->string('type'); // comment|catch|point
      $t->unsignedBigInteger('ref_id');
      $t->json('payload')->nullable();
      $t->enum('status',['pending','approved','rejected','error'])->default('pending');
      $t->string('provider')->nullable();
      $t->json('result')->nullable();
      $t->timestamps();
    });
  }
  public function down(): void { Schema::dropIfExists('moderation_queue'); }
};