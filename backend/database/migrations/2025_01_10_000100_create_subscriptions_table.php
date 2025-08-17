<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('subscriptions', function (Blueprint $t){
      $t->id();
      $t->unsignedBigInteger('user_id');
      $t->string('plan');
      $t->enum('period', ['month','year'])->default('month');
      $t->enum('status', ['active','past_due','canceled','expired'])->default('active');
      $t->dateTime('renews_at')->nullable();
      $t->string('provider')->nullable();
      $t->string('provider_sub_id')->nullable();
      $t->timestamps();
      $t->unique(['user_id','plan']);
      $t->index(['user_id','status']);
    });
  }
  public function down(): void { Schema::dropIfExists('subscriptions'); }
};