<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('plans', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('code')->unique();
            $table->string('title');
            $table->integer('price');
            $table->string('currency', 10)->default('RUB');
            $table->string('interval', 20)->default('month');
            $table->json('features')->nullable();
            $table->timestamps();
        });

        Schema::create('subscriptions', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('user_id')->default(0);
            $table->unsignedBigInteger('plan_id');
            $table->string('provider',20);
            $table->string('status',20)->default('active');
            $table->string('external_id')->nullable();
            $table->timestamp('renews_at')->nullable();
            $table->timestamps();
            $table->foreign('plan_id')->references('id')->on('plans')->onDelete('cascade');
        });

        Schema::create('payments', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('user_id')->default(0);
            $table->string('provider',20);
            $table->string('status',20)->default('pending');
            $table->integer('amount');
            $table->string('currency',10)->default('RUB');
            $table->string('external_id')->nullable();
            $table->json('payload')->nullable();
            $table->timestamps();
        });

        Schema::create('weather_cache', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('key');
            $table->text('current')->nullable();
            $table->text('daily')->nullable();
            $table->timestamp('fetched_at');
            $table->timestamps();
            $table->unique('key');
        });
    }
    public function down(): void
    {
        Schema::dropIfExists('weather_cache');
        Schema::dropIfExists('payments');
        Schema::dropIfExists('subscriptions');
        Schema::dropIfExists('plans');
    }
};
