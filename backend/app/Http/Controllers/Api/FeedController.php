<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Throwable;

class FeedController extends Controller
{
    public function index(Request $r)
    {
        try {
            $limit  = max(1, min((int)$r->input('limit', 20), 100));
            $offset = max(0, (int)$r->input('offset', 0));

            // Базовые поля, которые точно есть в catch_records (по вашей схеме)
            $select = [
                'catch_records.id',
                'catch_records.user_id',
                'catch_records.lat',
                'catch_records.lng',
                'catch_records.species',
                'catch_records.length',
                'catch_records.weight',
                'catch_records.depth',
                'catch_records.style',
                'catch_records.lure',
                'catch_records.tackle',
                'catch_records.privacy',
                'catch_records.caught_at',
                'catch_records.water_type',
                'catch_records.water_temp',
                'catch_records.wind_speed',
                'catch_records.pressure',
                'catch_records.companions',
                'catch_records.notes',
                'catch_records.photo_url',
                'catch_records.created_at',
            ];

            $q = DB::table('catch_records')->select($select);

            // privacy = 'all' (в вашей таблице дефолт 'all')
            $q->where('catch_records.privacy', '=', 'all');

            // Присоединим имя пользователя, если оно есть
            if (Schema::hasColumn('users', 'name')) {
                $q->leftJoin('users', 'users.id', '=', 'catch_records.user_id')
                  ->addSelect('users.name as user_name');
            } else {
                $q->addSelect(DB::raw("NULL as user_name"));
            }

            // Счётчики лайков/комментариев — подзапросами, если таблицы существуют
            if ($this->tableExists('catch_likes')) {
                $q->addSelect(DB::raw('(select count(*) from catch_likes cl where cl.catch_id = catch_records.id) as likes_count'));
            } else {
                $q->addSelect(DB::raw('0 as likes_count'));
            }

            if ($this->tableExists('catch_comments')) {
                $approvedCol = Schema::hasColumn('catch_comments','is_approved')
                    ? ' and cc.is_approved = 1' : '';
                $q->addSelect(DB::raw("(select count(*) from catch_comments cc where cc.catch_id = catch_records.id{$approvedCol}) as comments_count"));
            } else {
                $q->addSelect(DB::raw('0 as comments_count'));
            }

            // Поиск ?q= (species/notes/lure/tackle)
            if ($r->filled('q')) {
                $term = '%' . Str::lower(trim($r->input('q'))) . '%';
                $q->where(function ($w) use ($term) {
                    $w->whereRaw('LOWER(catch_records.species) LIKE ?', [$term])
                      ->orWhereRaw('LOWER(catch_records.notes) LIKE ?', [$term])
                      ->orWhereRaw('LOWER(catch_records.lure) LIKE ?', [$term])
                      ->orWhereRaw('LOWER(catch_records.tackle) LIKE ?', [$term]);
                });
            }

            // Фильтр по пользователю
            if ($r->filled('user_id')) {
                $q->where('catch_records.user_id', (int)$r->input('user_id'));
            }

            // bbox=minLng,minLat,maxLng,maxLat
            if ($r->filled('bbox')) {
                $parts = explode(',', $r->input('bbox'));
                if (count($parts) === 4) {
                    [$minLng,$minLat,$maxLng,$maxLat] = array_map('floatval', $parts);
                    $q->whereBetween('catch_records.lat', [$minLat, $maxLat])
                      ->whereBetween('catch_records.lng', [$minLng, $maxLng]);
                }
            }

            $items = $q->orderByDesc('catch_records.caught_at')
                       ->orderByDesc('catch_records.created_at')
                       ->offset($offset)->limit($limit)->get();

            return response()->json([
                'ok'    => true,
                'count' => $items->count(),
                'items' => $items,
            ]);
        } catch (Throwable $e) {
            report($e);
            return response()->json([
                'ok' => false,
                'error' => 'feed_failed',
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    private function tableExists(string $name): bool
    {
        try {
            return DB::getDoctrineSchemaManager()->tablesExist([$name]);
        } catch (Throwable $e) {
            try { DB::table($name)->limit(1)->get(); return true; }
            catch (Throwable $e2) { return false; }
        }
    }
}