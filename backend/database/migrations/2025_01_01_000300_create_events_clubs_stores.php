<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        if (!Schema::hasTable('events')) {
            Schema::create('events', function (Blueprint $table) {
                $table->id();
                $table->string('title');
                $table->string('region')->nullable();
                $table->dateTime('starts_at')->nullable();
                $table->dateTime('ends_at')->nullable();
                $table->text('description')->nullable();
                $table->double('location_lat')->nullable(); $table->double('location_lng')->nullable();
                $table->string('link')->nullable();
                $table->unsignedBigInteger('org_club_id')->nullable();
                $table->timestamps();
            });
        }
        if (!Schema::hasTable('clubs')) {
            Schema::create('clubs', function (Blueprint $table) {
                $table->id();
                $table->string('name');
                $table->string('logo_url')->nullable();
                $table->string('region')->nullable();
                $table->integer('members_count')->default(0);
                $table->text('description')->nullable();
                $table->timestamps();
            });
        }
        if (!Schema::hasTable('stores')) {
            Schema::create('stores', function (Blueprint $table) {
                $table->id();
                $table->string('name'); $table->string('address')->nullable();
                $table->double('lat')->nullable(); $table->double('lng')->nullable();
                $table->string('url')->nullable(); $table->string('category')->default('tackle');
                $table->timestamps();
            });
        }
    }
    public function down(): void { Schema::dropIfExists('events'); Schema::dropIfExists('clubs'); Schema::dropIfExists('stores'); }
};
