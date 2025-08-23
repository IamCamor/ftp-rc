<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'is_pro')) {
                $table->boolean('is_pro')->default(false)->index();
            }
            if (!Schema::hasColumn('users', 'pro_until')) {
                $table->timestamp('pro_until')->nullable()->index();
            }
        });
    }
    public function down(): void {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'is_pro')) $table->dropColumn('is_pro');
            if (Schema::hasColumn('users', 'pro_until')) $table->dropColumn('pro_until');
        });
    }
};
