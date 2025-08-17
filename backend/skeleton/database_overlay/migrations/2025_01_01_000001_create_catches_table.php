<?php
use Illuminate\Database\Migrations\Migration; use Illuminate\Database\Schema\Blueprint; use Illuminate\Support\Facades\Schema;
return new class extends Migration { public function up(): void {
 Schema::create('catch_records', function (Blueprint $t){ $t->id(); $t->foreignId('user_id')->constrained()->cascadeOnDelete(); $t->decimal('lat',10,7); $t->decimal('lng',10,7); $t->string('species')->nullable(); $t->float('length')->nullable(); $t->float('weight')->nullable(); $t->float('depth')->nullable(); $t->string('style')->nullable(); $t->string('lure')->nullable(); $t->string('tackle')->nullable(); $t->unsignedBigInteger('friend_id')->nullable(); $t->string('privacy')->default('all'); $t->timestamps(); });
} public function down(): void { Schema::dropIfExists('catch_records'); } };