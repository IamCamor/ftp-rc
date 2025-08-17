<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        // таблица уже есть -> мягко добавляем недостающие поля
        if (!Schema::hasTable('catch_comments')) return;

        if (!Schema::hasColumn('catch_comments', 'text') && Schema::hasColumn('catch_comments', 'body')) {
            Schema::table('catch_comments', function (Blueprint $t) {
                $t->text('text')->nullable();
            });
            DB::statement("UPDATE catch_comments SET text = body WHERE text IS NULL");
        }

        if (!Schema::hasColumn('catch_comments', 'status') && Schema::hasColumn('catch_comments', 'is_approved')) {
            Schema::table('catch_comments', function (Blueprint $t) {
                // string вместо enum — дружелюбно к SQLite
                $t->string('status')->default('approved');
            });
            DB::statement("UPDATE catch_comments SET status = CASE WHEN is_approved=1 THEN 'approved' ELSE 'pending' END");
        }
    }

    public function down(): void
    {
        // Ничего не откатываем — чтобы не потерять данные
    }
};
