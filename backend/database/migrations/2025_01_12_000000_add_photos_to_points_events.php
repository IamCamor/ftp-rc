<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        if (Schema::hasTable('fishing_points') && !Schema::hasColumn('fishing_points','photo_url')) {
            Schema::table('fishing_points', function (Blueprint $table) { $table->string('photo_url')->nullable()->after('description'); });
        }
        if (Schema::hasTable('events') && !Schema::hasColumn('events','photo_url')) {
            Schema::table('events', function (Blueprint $table) { $table->string('photo_url')->nullable()->after('description'); });
        }
    }
    public function down(): void {
        if (Schema::hasTable('fishing_points') && Schema::hasColumn('fishing_points','photo_url')) {
            Schema::table('fishing_points', function (Blueprint $table) { $table->dropColumn('photo_url'); });
        }
        if (Schema::hasTable('events') && Schema::hasColumn('events','photo_url')) {
            Schema::table('events', function (Blueprint $table) { $table->dropColumn('photo_url'); });
        }
    }
};
