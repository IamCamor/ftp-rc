<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
  public function up(): void {
    if (!Schema::hasTable('media')) {
      Schema::create('media', function(Blueprint $t){
        $t->id();
        $t->string('disk')->default('public');
        $t->string('path');
        $t->string('url');
        $t->string('type')->nullable();
        $t->unsignedBigInteger('size')->nullable();
        $t->json('meta')->nullable();
        $t->timestamps();
      });
    }
    if (Schema::hasTable('fishing_points') && !Schema::hasColumn('fishing_points','photo_id')) {
      Schema::table('fishing_points', fn(Blueprint $t)=>$t->unsignedBigInteger('photo_id')->nullable()->after('is_approved'));
    }
    if (Schema::hasTable('catch_records') && !Schema::hasColumn('catch_records','photo_id')) {
      Schema::table('catch_records', fn(Blueprint $t)=>$t->unsignedBigInteger('photo_id')->nullable()->after('privacy'));
    }
  }
  public function down(): void {
    if (Schema::hasTable('fishing_points') && Schema::hasColumn('fishing_points','photo_id')) {
      Schema::table('fishing_points', fn(Blueprint $t)=>$t->dropColumn('photo_id'));
    }
    if (Schema::hasTable('catch_records') && Schema::hasColumn('catch_records','photo_id')) {
      Schema::table('catch_records', fn(Blueprint $t)=>$t->dropColumn('photo_id'));
    }
    if (Schema::hasTable('media')) Schema::drop('media');
  }
};
