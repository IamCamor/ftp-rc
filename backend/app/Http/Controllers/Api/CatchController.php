<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Carbon\Carbon;

class CatchController extends Controller
{
    /**
     * Возвращает один улов по id в едином формате для фронта.
     */
    public function show($id)
    {
        // Базовые поля из catch_records + имя пользователя.
        $row = DB::table('catch_records as cr')
            ->leftJoin('users as u', 'u.id', '=', 'cr.user_id')
            ->where('cr.id', '=', $id)
            ->selectRaw("
                cr.id,
                cr.user_id,
                u.name as user_name,
                cr.lat, cr.lng,
                cr.species,
                cr.length,
                cr.weight,
                cr.depth,
                cr.style as method,
                cr.lure as bait,
                cr.tackle as gear,
                cr.privacy,
                cr.caught_at,
                cr.notes as caption,
                cr.photo_url as media_url,
                cr.created_at,
                (SELECT COUNT(*) FROM catch_likes   cl WHERE cl.catch_id = cr.id)                                          AS likes_count,
                (SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id = cr.id AND (cc.is_approved=1 OR cc.is_approved IS NULL)) AS comments_count
            ")
            ->first();

        if (!$row) {
            return response()->json(['message' => 'Catch not found'], 404);
        }

        // Аккуратно подставляем аватар пользователя: не трогаем БД-колонки, которых нет.
        $userAvatar = config('ui.assets.default_avatar') ?? '';
        if ($row->user_id) {
            // Если в вашей таблице users есть одна из колонок — можно попытаться взять.
            // Но без риска падений: проверяем наличие перед запросом.
            $avatarCol = null;
            foreach (['avatar_url', 'avatar', 'photo_url'] as $c) {
                if (Schema::hasColumn('users', $c)) { $avatarCol = $c; break; }
            }
            if ($avatarCol) {
                $val = DB::table('users')->where('id', $row->user_id)->value($avatarCol);
                if ($val) $userAvatar = $val;
            }
        }

        // Собираем итоговый объект
        $item = [
            'id'            => (int)$row->id,
            'user_id'       => $row->user_id,
            'user_name'     => $row->user_name,
            'user_avatar'   => $userAvatar,
            'lat'           => (float)$row->lat,
            'lng'           => (float)$row->lng,
            'species'       => $row->species,
            'length'        => $row->length,
            'weight'        => $row->weight,
            'depth'         => $row->depth,
            'method'        => $row->method,
            'bait'          => $row->bait,
            'gear'          => $row->gear,
            'privacy'       => $row->privacy,
            'caught_at'     => $row->caught_at,
            'caption'       => $row->caption,
            'media_url'     => $row->media_url,
            'likes_count'   => (int)$row->likes_count,
            'comments_count'=> (int)$row->comments_count,
            'created_at'    => $row->created_at,
        ];

        return response()->json($item);
    }

    /**
     * Создание улова. Принимает ISO-8601 / UNIX ts / локальные строки, нормализует caught_at в UTC DATETIME.
     */
    public function store(Request $r)
    {
        $data = $r->validate([
            'lat'        => 'required|numeric',
            'lng'        => 'required|numeric',
            'species'    => 'nullable|string|max:255',
            'length'     => 'nullable|numeric',
            'weight'     => 'nullable|numeric',
            'depth'      => 'nullable|numeric',
            'style'      => 'nullable|string|max:255',
            'lure'       => 'nullable|string|max:255',
            'tackle'     => 'nullable|string|max:255',
            'privacy'    => 'nullable|in:all,friends,private',
            'caught_at'  => 'nullable',
            'notes'      => 'nullable|string',
            'photo_url'  => 'nullable|string|max:1024',
            'media_urls' => 'sometimes|array',
            'media_urls.*' => 'string|max:2048',
            'point_id'   => 'nullable|integer',
        ]);

        $data['caught_at'] = $this->normalizeDateTime($r->input('caught_at')) ?? now('UTC')->format('Y-m-d H:i:s');
        $userId = optional($r->user())->id; // гость -> null, если у вас нужна авторизация, подключите sanctum
        $privacy = $data['privacy'] ?? 'all';

        $id = DB::table('catch_records')->insertGetId([
            'user_id'    => $userId,
            'lat'        => $data['lat'],
            'lng'        => $data['lng'],
            'species'    => $data['species'] ?? null,
            'length'     => $data['length'] ?? null,
            'weight'     => $data['weight'] ?? null,
            'depth'      => $data['depth'] ?? null,
            'style'      => $data['style'] ?? null,
            'lure'       => $data['lure'] ?? null,
            'tackle'     => $data['tackle'] ?? null,
            'privacy'    => $privacy,
            'caught_at'  => $data['caught_at'],
            'notes'      => $data['notes'] ?? null,
            'photo_url'  => $data['photo_url'] ?? null,
            'created_at' => now('UTC'),
            'updated_at' => now('UTC'),
        ]);

        if ($r->filled('media_urls') && is_array($r->input('media_urls'))) {
            $bulk = [];
            foreach ($r->input('media_urls') as $url) {
                $bulk[] = [
                    'owner_type' => 'catch',
                    'owner_id'   => $id,
                    'url'        => $url,
                    'kind'       => $this->guessKindFromUrl($url),
                    'created_at' => now('UTC'),
                    'updated_at' => now('UTC'),
                ];
            }
            if ($bulk) DB::table('media')->insert($bulk);
        }

        return $this->show($id);
    }

    private function normalizeDateTime($value): ?string
    {
        if (empty($value)) return null;

        try {
            if (is_numeric($value)) {
                $ts = (int)$value;
                if ($ts > 10_000_000_000) { // мс -> с
                    $ts = (int) round($ts / 1000);
                }
                return Carbon::createFromTimestamp($ts, 'UTC')->format('Y-m-d H:i:s');
            }

            $c = Carbon::parse($value); // ISO-8601 и др.
            return $c->setTimezone('UTC')->format('Y-m-d H:i:s');
        } catch (\Throwable $e) {
            try {
                $clean = str_replace(['T', 'Z'], [' ', ''], (string)$value);
                $c = Carbon::parse($clean);
                return $c->setTimezone('UTC')->format('Y-m-d H:i:s');
            } catch (\Throwable $e2) {
                return null;
            }
        }
    }

    private function guessKindFromUrl(string $url): string
    {
        $ext = Str::lower(pathinfo(parse_url($url, PHP_URL_PATH) ?? '', PATHINFO_EXTENSION));
        return in_array($ext, ['mp4','mov','webm','m4v']) ? 'video' : 'photo';
    }
}