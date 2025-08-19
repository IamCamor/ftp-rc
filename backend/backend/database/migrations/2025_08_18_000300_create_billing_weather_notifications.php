<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('plans', function (Blueprint $t) {
      $t->bigIncrements('id');
      $t->string('code')->unique();
      $t->string('title');
      $t->integer('price');
      $t->string('currency',10)->default('RUB');
      $t->string('interval',20)->default('month');
      $t->json('features')->nullable();
      $t->timestamps();
    });
    Schema::create('payments', function (Blueprint $t) {
      $t->bigIncrements('id');
      $t->unsignedBigInteger('user_id')->default(0);
      $t->string('provider',20);
      $t->string('status',20)->default('pending');
      $t->integer('amount');
      $t->string('currency',10)->default('RUB');
      $t->string('external_id')->nullable();
      $t->json('payload')->nullable();
      $t->timestamps();
    });
    Schema::create('weather_cache', function (Blueprint $t) {
      $t->bigIncrements('id');
      $t->string('key')->unique();
      $t->text('current')->nullable();
      $t->text('daily')->nullable();
      $t->timestamp('fetched_at');
      $t->timestamps();
    });
    Schema::create('notifications', function (Blueprint $t) {
      $t->bigIncrements('id');
      $t->unsignedBigInteger('user_id')->default(0);
      $t->string('type',30)->default('system');
      $t->string('title');
      $t->text('body')->nullable();
      $t->boolean('is_read')->default(false);
      $t->timestamps();
    });
    Schema::create('notification_settings', function (Blueprint $t) {
      $t->bigIncrements('id');
      $t->unsignedBigInteger('user_id')->default(0);
      $t->boolean('push_enabled')->default(false);
      $t->boolean('email_enabled')->default(true);
      $t->boolean('likes_enabled')->default(true);
      $t->boolean('comments_enabled')->default(true);
      $t->boolean('system_enabled')->default(true);
      $t->timestamps();
    });
  }
  public function down(): void {
    Schema::dropIfExists('notification_settings');
    Schema::dropIfExists('notifications');
    Schema::dropIfExists('weather_cache');
    Schema::dropIfExists('payments');
    Schema::dropIfExists('plans');
  }
};
