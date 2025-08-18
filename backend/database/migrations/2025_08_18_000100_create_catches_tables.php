<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('catches', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->double('lat',10,6)->nullable();
            $table->double('lng',10,6)->nullable();
            $table->string('species')->nullable();
            $table->float('length')->nullable();
            $table->float('weight')->nullable();
            $table->float('depth')->nullable();
            $table->string('style',50)->nullable();
            $table->string('lure')->nullable();
            $table->string('tackle')->nullable();
            $table->string('privacy',20)->nullable()->default('all');
            $table->string('companions')->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('caught_at')->nullable();
            $table->timestamps();
        });

        Schema::create('catch_media', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('catch_id');
            $table->string('url');
            $table->string('type',20)->default('image');
            $table->timestamps();
            $table->foreign('catch_id')->references('id')->on('catches')->onDelete('cascade');
        });

        Schema::create('catch_comments', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('catch_id');
            $table->unsignedBigInteger('user_id')->default(0);
            $table->text('body');
            $table->boolean('is_approved')->default(true);
            $table->timestamps();
            $table->foreign('catch_id')->references('id')->on('catches')->onDelete('cascade');
        });

        Schema::create('catch_likes', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('catch_id');
            $table->unsignedBigInteger('user_id')->default(0);
            $table->timestamps();
            $table->unique(['catch_id','user_id']);
            $table->foreign('catch_id')->references('id')->on('catches')->onDelete('cascade');
        });
    }
    public function down(): void
    {
        Schema::dropIfExists('catch_likes');
        Schema::dropIfExists('catch_comments');
        Schema::dropIfExists('catch_media');
        Schema::dropIfExists('catches');
    }
};
