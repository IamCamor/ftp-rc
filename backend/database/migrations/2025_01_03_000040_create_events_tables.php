<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('events', function (Blueprint $t){
      $t->id();
      $t->string('title');
      $t->text('description')->nullable();
      $t->dateTime('starts_at');
      $t->dateTime('ends_at')->nullable();
      $t->string('region')->nullable();
      $t->unsignedBigInteger('creator_id');
      $t->timestamps();
      $t->index(['starts_at','region']);
    });
    Schema::create('event_subscriptions', function (Blueprint $t){
      $t->id();
      $t->unsignedBigInteger('event_id');
      $t->unsignedBigInteger('user_id');
      $t->timestamps();
      $t->unique(['event_id','user_id']);
      $t->index('user_id');
    });
  }
  public function down(): void {
    Schema::dropIfExists('event_subscriptions');
    Schema::dropIfExists('events');
  }
};