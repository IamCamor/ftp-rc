<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('clubs', function (Blueprint $t){
      $t->id();
      $t->string('name');
      $t->string('logo')->nullable();
      $t->text('description')->nullable();
      $t->unsignedBigInteger('owner_id');
      $t->timestamps();
      $t->index('owner_id');
    });
    Schema::create('club_members', function (Blueprint $t){
      $t->id();
      $t->unsignedBigInteger('club_id');
      $t->unsignedBigInteger('user_id');
      $t->enum('role', ['member','moderator','admin'])->default('member');
      $t->timestamps();
      $t->unique(['club_id','user_id']);
      $t->index('user_id');
    });
  }
  public function down(): void {
    Schema::dropIfExists('club_members');
    Schema::dropIfExists('clubs');
  }
};