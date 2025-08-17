<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // --- catch_comments ---
        if (!Schema::hasTable('catch_comments')) {
            // если таблицы нет — создадим (любой исходный вариант)
            Schema::create('catch_comments', function (Blueprint $t) {
                $t->id();
                $t->unsignedBigInteger('catch_id');
                $t->unsignedBigInteger('user_id');
                // используем "text/status" как целевую схему (дружелюбно к SQLite)
                $t->text('text');
                $t->string('status')->default('approved');
                $t->timestamps();
                $t->index('catch_id');
                // FK можно добавить, если у тебя есть таблицы users/catch_records
                // $t->foreign('catch_id')->references('id')->on('catch_records')->onDelete('cascade');
                // $t->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            });
        } else {
            // таблица уже есть — мягко добавим недостающие колонки
            if (!Schema::hasColumn('catch_comments', 'text') && Schema::hasColumn('catch_comments', 'body')) {
                Schema::table('catch_comments', function (Blueprint $t) {
                    $t->text('text')->nullable();
                });
                DB::statement("UPDATE catch_comments SET text = body WHERE text IS NULL");
            }
            if (!Schema::hasColumn('catch_comments', 'status') && Schema::hasColumn('catch_comments', 'is_approved')) {
                Schema::table('catch_comments', function (Blueprint $t) {
                    $t->string('status')->default('approved');
                });
                DB::statement("UPDATE catch_comments SET status = CASE WHEN is_approved=1 THEN 'approved' ELSE 'pending' END");
            }
        }

        // --- catch_likes ---
        if (!Schema::hasTable('catch_likes')) {
            Schema::create('catch_likes', function (Blueprint $t) {
                $t->id();
                $t->unsignedBigInteger('catch_id');
                $t->unsignedBigInteger('user_id');
                $t->timestamps();
                $t->unique(['catch_id','user_id']);
                $t->index('catch_id');
                // FK по желанию:
                // $t->foreign('catch_id')->references('id')->on('catch_records')->onDelete('cascade');
                // $t->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            });
        }
    }

    public function down(): void
    {
        // безопасный откат: ничего не дропаем, чтобы не потерять данные
        // если очень нужно — можно раскомментировать:
        // Schema::dropIfExists('catch_likes');
        // Schema::dropIfExists('catch_comments');
    }
};
