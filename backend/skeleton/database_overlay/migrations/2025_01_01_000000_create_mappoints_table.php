<?php
use Illuminate\Database\Migrations\Migration; use Illuminate\Database\Schema\Blueprint; use Illuminate\Support\Facades\Schema;
return new class extends Migration { public function up(): void {
 Schema::create('map_points', function (Blueprint $t){ $t->id(); $t->string('title'); $t->text('description')->nullable(); $t->decimal('lat',10,7); $t->decimal('lng',10,7); $t->string('type')->default('spot'); $t->boolean('is_featured')->default(false); $t->string('visibility')->default('public'); $t->timestamps(); });
} public function down(): void { Schema::dropIfExists('map_points'); } };