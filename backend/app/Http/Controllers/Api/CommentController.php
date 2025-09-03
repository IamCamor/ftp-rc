<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class CommentController extends Controller
{
    public function store(Request $r, $catchId)
    {
        // Принимаем text | comment | body | message
        $raw = $r->input('text', $r->input('comment', $r->input('body', $r->input('message', null))));
        $text = is_string($raw) ? trim($raw) : '';

        if ($text === '') {
            return response()->json([
                'message' => 'Validation error',
                'errors' => ['text' => ['Поле комментария обязательно']],
            ], 422);
        }

        $userId = optional($r->user())->id;
        $parentId = $r->integer('parent_id');
        $now = now();

        // Набор полей к insert — минимально совместимый
        $insert = [
            'catch_id'   => (int)$catchId,
            'user_id'    => $userId,
            'parent_id'  => $parentId ?: null,
            'text'       => $text,
            'created_at' => $now,
            'updated_at' => $now,
        ];

        // Если есть колонка is_approved — одобряем сразу
        if (Schema::hasColumn('catch_comments', 'is_approved')) {
            $insert['is_approved'] = 1;
        }

        // Опционально поддержим author_name, если колонка существует
        if (!$userId && Schema::hasColumn('catch_comments', 'author_name')) {
            $guest = trim((string)$r->input('guest_name', ''));
            $insert['author_name'] = $guest !== '' ? $guest : null;
        }

        $id = DB::table('catch_comments')->insertGetId($insert);

        // Вернём карточку комментария с именем и аватаром (если есть)
        $select = "
            cc.id, cc.catch_id, cc.parent_id, cc.text, cc.created_at
        ";
        if (Schema::hasColumn('catch_comments','is_approved')) {
            $select .= ", cc.is_approved";
        }

        $avatarExpr = "COALESCE(u.avatar_url, u.photo_url, '')";
        $nameExpr   = "COALESCE(u.name, 'Гость')";
        if (Schema::hasColumn('catch_comments','author_name')) {
            $nameExpr = "COALESCE(u.name, cc.author_name, 'Гость')";
        }

        $item = DB::table('catch_comments as cc')
            ->leftJoin('users as u','u.id','=','cc.user_id')
            ->selectRaw($select . ",
                $nameExpr as author_name,
                $avatarExpr as author_avatar
            ")
            ->where('cc.id', $id)
            ->first();

        return response()->json(['item' => $item], 201);
    }
}
