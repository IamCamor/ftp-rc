<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('events', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('title');
            $table->string('region')->nullable();
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->text('description')->nullable();
            $table->double('location_lat',10,6)->nullable();
            $table->double('location_lng',10,6)->nullable();
            $table->string('link')->nullable();
            $table->string('photo_url')->nullable();
            $table->timestamps();
        });

        Schema::create('clubs', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('name');
            $table->string('region')->nullable();
            $table->text('description')->nullable();
            $table->string('logo_url')->nullable();
            $table->timestamps();
        });

        Schema::create('club_members', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('club_id');
            $table->unsignedBigInteger('user_id')->default(0);
            $table->string('role',20)->default('member');
            $table->timestamps();
            $table->unique(['club_id','user_id']);
            $table->foreign('club_id')->references('id')->on('clubs')->onDelete('cascade');
        });
    }
    public function down(): void
    {
        Schema::dropIfExists('club_members');
        Schema::dropIfExists('clubs');
        Schema::dropIfExists('events');
    }
};
