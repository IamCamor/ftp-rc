<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('payments', function (Blueprint $t){
      $t->id();
      $t->unsignedBigInteger('user_id')->nullable();
      $t->string('provider');
      $t->string('intent_id')->nullable();
      $t->string('status')->default('pending');
      $t->string('currency', 8)->default('RUB');
      $t->decimal('amount', 12, 2)->default(0);
      $t->string('purpose')->nullable();
      $t->json('metadata')->nullable();
      $t->timestamps();
      $t->index(['provider','status']);
    });
  }
  public function down(): void { Schema::dropIfExists('payments'); }
};