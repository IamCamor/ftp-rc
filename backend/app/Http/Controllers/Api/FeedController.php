<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class FeedController extends Controller
{
    /**
     * GET /api/v1/feed?scope=global|local|follow&lat=..&lng=..&radius_km=50&page=1&per=20
     * Публичная лента. Возвращает карточки уловов.
     */
    public function index(Request $r)
    {
        $scope   = $r->query('scope', 'global');
        $lat     = $r->float('lat', null);
        $lng     = $r->float('lng', null);
        $radius  = max(1, min((int)$r->query('radius_km', 50), 500)); // км
        $perPage = max(1, min((int)$r->query('per', 20), 50));

        // Базовый селект: catch_records + автор
        $q = DB::table('catch_records')
            ->leftJoin('users', 'users.id', '=', 'catch_records.user_id')
            ->select([
                'catch_records.id',
                'catch_records.user_id',
                'users.name as user_name',
                'users.avatar as user_avatar',
                // поля улова — берём мягко (если нет в схеме, просто будут null)
                'catch_records.lat',
                'catch_records.lng',
                'catch_records.species',
                'catch_records.size_cm',
                'catch_records.weight_g',
                'catch_records.method',
                'catch_records.gear',
                'catch_records.bait',
                'catch_records.caption',
                'catch_records.media_url',
                'catch_records.created_at',
            ])
            // счётчики (через подзапросы)
            ->selectRaw('(select count(*) from catch_likes cl where cl.catch_id = catch_records.id) as likes_count')
            ->selectRaw('(select count(*) from catch_comments cc where cc.catch_id = catch_records.id'
                . (Schema::hasColumn('catch_comments', 'is_approved') ? ' and cc.is_approved = 1' : '')
                . ') as comments_count');

        // Флаг "понравилось мне"
        $uid = Auth::id();
        if ($uid) {
            $q->selectRaw('exists(select 1 from catch_likes me where me.catch_id = catch_records.id and me.user_id = ?) as liked_by_me', [$uid]);
        } else {
            $q->selectRaw('0 as liked_by_me');
        }

        // Фильтрация приватности / модерации — мягкая, только если есть такие колонки
        if (Schema::hasColumn('catch_records', 'privacy')) {
            $q->where('catch_records.privacy', 'public');
        }
        if (Schema::hasColumn('catch_records', 'status')) {
            $q->where('catch_records.status', 'approved');
        }

        // Скоупы: global | local | follow
        if ($scope === 'local' && $lat !== null && $lng !== null) {
            // Упрощённый радиус через bbox (быстро и без HAVERSINE)
            $deg = $radius / 111; // ~1° широты ≈ 111 км
            if (Schema::hasColumns('catch_records', ['lat', 'lng'])) {
                $q->whereBetween('catch_records.lat', [$lat - $deg, $lat + $deg])
                  ->whereBetween('catch_records.lng', [$lng - $deg, $lng + $deg]);
            }
        } elseif ($scope === 'follow' && $uid) {
            // Нужна таблица подписок, иначе вернём пусто
            if (Schema::hasTable('follows')) {
                $q->whereIn('catch_records.user_id', function ($sub) use ($uid) {
                    $sub->from('follows')->select('followee_id')->where('follower_id', $uid);
                });
            } else {
                $q->whereRaw('1 = 0'); // нет таблицы — по контракту пустая лента follow
            }
        }

        // Сортировка
        if (Schema::hasColumn('catch_records', 'created_at')) {
            $q->orderByDesc('catch_records.created_at');
        } else {
            $q->orderByDesc('catch_records.id');
        }

        $page = $q->paginate($perPage)->appends($r->query());

        return response()->json([
            'items' => $page->items(),
            'meta'  => [
                'current_page' => $page->currentPage(),
                'per_page'     => $page->perPage(),
                'total'        => $page->total(),
                'next'         => $page->nextPageUrl(),
                'prev'         => $page->previousPageUrl(),
            ]
        ]);
    }

    /**
     * POST /api/v1/feed/{id}/like  (auth)
     */
    public function like(Request $r, int $id)
    {
        $uid = Auth::id();
        if (!$uid) return response()->json(['message' => 'Unauthorized'], 401);
        if (!Schema::hasTable('catch_likes')) return response()->json(['message' => 'likes table missing'], 500);

        DB::table('catch_likes')->updateOrInsert(
            ['catch_id' => $id, 'user_id' => $uid],
            ['created_at' => now(), 'updated_at' => now()]
        );
        return response()->json(['ok' => true]);
    }

    /**
     * DELETE /api/v1/feed/{id}/like  (auth)
     */
    public function unlike(Request $r, int $id)
    {
        $uid = Auth::id();
        if (!$uid) return response()->json(['message' => 'Unauthorized'], 401);
        if (!Schema::hasTable('catch_likes')) return response()->json(['message' => 'likes table missing'], 500);

        DB::table('catch_likes')->where(['catch_id' => $id, 'user_id' => $uid])->delete();
        return response()->json(['ok' => true]);
    }

    /**
     * GET /api/v1/feed/{id}/comments  — публично
     */
    public function comments(Request $r, int $id)
    {
        if (!Schema::hasTable('catch_comments')) return response()->json(['items' => []]);

        $q = DB::table('catch_comments')
            ->leftJoin('users', 'users.id', '=', 'catch_comments.user_id')
            ->where('catch_comments.catch_id', $id)
            ->select([
                'catch_comments.id',
                'catch_comments.body',
                'catch_comments.created_at',
                'users.id as user_id',
                'users.name as user_name',
                'users.avatar as user_avatar',
            ]);

        if (Schema::hasColumn('catch_comments', 'is_approved')) {
            $q->where('catch_comments.is_approved', 1);
        }

        $items = $q->orderBy('catch_comments.id', 'asc')->limit(200)->get();

        return response()->json(['items' => $items]);
    }

    /**
     * POST /api/v1/feed/{id}/comments  (auth)
     */
    public function addComment(Request $r, int $id)
    {
        $uid = Auth::id();
        if (!$uid) return response()->json(['message' => 'Unauthorized'], 401);
        if (!Schema::hasTable('catch_comments')) return response()->json(['message' => 'comments table missing'], 500);

        $data = $r->validate(['body' => 'required|string|min:1|max:2000']);

        $row = [
            'catch_id'   => $id,
            'user_id'    => $uid,
            'body'       => $data['body'],
            'created_at' => now(),
            'updated_at' => now(),
        ];
        if (Schema::hasColumn('catch_comments', 'is_approved')) {
            $row['is_approved'] = 1; // автодопуск — можно переключить на модерацию
        }

        $cid = DB::table('catch_comments')->insertGetId($row);

        return response()->json([
            'id'   => $cid,
            'body' => $data['body']
        ], 201);
    }
}