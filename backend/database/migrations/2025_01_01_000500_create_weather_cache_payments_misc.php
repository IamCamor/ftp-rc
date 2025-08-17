<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        if (!Schema::hasTable('weather_cache')) {
            Schema::create('weather_cache', function (Blueprint $table) {
                $table->id();
                $table->string('key')->unique();
                $table->text('current')->nullable();
                $table->text('daily')->nullable();
                $table->timestamp('fetched_at');
                $table->timestamps();
            });
        }
        if (!Schema::hasTable('payments')) {
            Schema::create('payments', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->nullable();
                $table->string('provider'); $table->string('provider_ref')->nullable();
                $table->integer('amount'); $table->string('currency',10)->default('RUB');
                $table->string('status')->default('pending');
                $table->json('meta')->nullable();
                $table->timestamps();
            });
        }
        if (!Schema::hasTable('subscriptions')) {
            Schema::create('subscriptions', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->nullable();
                $table->string('plan_id');
                $table->string('status')->default('active');
                $table->timestamp('started_at')->nullable();
                $table->timestamp('renews_at')->nullable();
                $table->timestamp('ends_at')->nullable();
                $table->timestamps();
            });
        }
        if (!Schema::hasTable('push_subscriptions')) {
            Schema::create('push_subscriptions', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->nullable();
                $table->string('platform', 20);
                $table->text('token');
                $table->timestamp('last_seen_at')->nullable();
                $table->timestamps();
            });
        }
        if (!Schema::hasTable('analytics_events')) {
            Schema::create('analytics_events', function (Blueprint $table) {
                $table->id();
                $table->string('name'); $table->unsignedBigInteger('user_id')->nullable();
                $table->text('payload')->nullable(); $table->string('ip',45)->nullable(); $table->string('ua')->nullable();
                $table->timestamps();
            });
        }
    }
    public function down(): void {
        Schema::dropIfExists('weather_cache'); Schema::dropIfExists('payments'); Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('push_subscriptions'); Schema::dropIfExists('analytics_events');
    }
};
