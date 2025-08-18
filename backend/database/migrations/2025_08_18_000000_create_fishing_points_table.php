<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('fishing_points', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('title');
            $table->text('description')->nullable();
            $table->enum('category',['spot','shop','slip','resort'])->default('spot');
            $table->double('lat', 10, 6);
            $table->double('lng', 10, 6);
            $table->boolean('is_public')->default(true);
            $table->boolean('is_highlighted')->default(false);
            $table->string('photo_url')->nullable();
            $table->timestamps();
            $table->index(['category','is_public']);
        });
    }
    public function down(): void
    {
        Schema::dropIfExists('fishing_points');
    }
};
