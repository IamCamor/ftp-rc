<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
  public function up(): void {
    if (!Schema::hasTable('catch_comments')) {
      Schema::create('catch_comments', function (Blueprint $t) {
        $t->id();
        $t->unsignedBigInteger('catch_id');
        $t->unsignedBigInteger('user_id');
        $t->text('text');
        $t->string('status')->default('pending'); // string вместо ENUM для SQLite совместимости
        $t->timestamps();
        $t->index('catch_id');
      });
      return;
    }

    // Таблица уже есть — мягко добавим недостающие поля и перенесём данные
    if (!Schema::hasColumn('catch_comments', 'text') && Schema::hasColumn('catch_comments', 'body')) {
      Schema::table('catch_comments', function (Blueprint $t) { $t->text('text')->nullable(); });
      DB::statement("UPDATE catch_comments SET text = body WHERE text IS NULL");
    }
    if (!Schema::hasColumn('catch_comments', 'status') && Schema::hasColumn('catch_comments', 'is_approved')) {
      Schema::table('catch_comments', function (Blueprint $t) { $t->string('status')->default('approved'); });
      DB::statement("UPDATE catch_comments SET status = CASE WHEN is_approved=1 THEN 'approved' ELSE 'pending' END");
    }
  }

  public function down(): void {
    // ничего не удаляем, чтобы не потерять существующие данные
  }
};
