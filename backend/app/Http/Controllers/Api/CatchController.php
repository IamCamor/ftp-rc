<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\Rule;

class CatchController extends Controller
{
    /**
     * Публичная лента уловов (privacy = all), сортировка: новые сверху.
     * GET /api/v1/feed?limit=20&offset=0
     */
    public function index(Request $request)
    {
        $limit  = (int) $request->integer('limit', 20);
        $offset = (int) $request->integer('offset', 0);

        // Выбираем подходящее поле аватарки, чтобы не падать, если 'avatar' отсутствует
        $avatarExpr = $this->userAvatarExpr();

        $rows = DB::table('catch_records as cr')
            ->leftJoin('users as u', 'u.id', '=', 'cr.user_id')
            ->selectRaw("
                cr.id, cr.user_id,
                u.name as user_name,
                {$avatarExpr} as user_avatar,
                cr.lat, cr.lng,
                cr.species, cr.length, cr.weight, cr.depth,
                cr.style, cr.lure, cr.tackle,
                cr.notes, cr.photo_url,
                cr.caught_at, cr.created_at,
                (select count(*) from catch_likes cl where cl.catch_id = cr.id) as likes_count,
                (select count(*) from catch_comments cc where cc.catch_id = cr.id and (cc.is_approved = 1 or cc.is_approved is null)) as comments_count
            ")
            ->where('cr.privacy', '=', 'all')
            ->orderByDesc('cr.created_at')
            ->limit($limit)
            ->offset($offset)
            ->get();

        return response()->json([
            'items'  => $rows,
            'limit'  => $limit,
            'offset' => $offset,
            'next'   => $offset + $rows->count(),
        ]);
    }

    /**
     * Детальная карточка улова.
     * GET /api/v1/catch/{id}
     */
    public function show(Request $request, $id)
    {
        $avatarExpr = $this->userAvatarExpr();

        $row = DB::table('catch_records as cr')
            ->leftJoin('users as u', 'u.id', '=', 'cr.user_id')
            ->selectRaw("
                cr.*,
                u.name as user_name,
                {$avatarExpr} as user_avatar,
                (select count(*) from catch_likes cl where cl.catch_id = cr.id) as likes_count,
                (select count(*) from catch_comments cc where cc.catch_id = cr.id and (cc.is_approved = 1 or cc.is_approved is null)) as comments_count
            ")
            ->where('cr.id', '=', $id)
            ->first();

        if (!$row) {
            return response()->json(['message' => 'Not found'], 404);
        }

        // Гостям отдаём только публичные записи
        if ($row->privacy !== 'all') {
            // TODO: если будет авторизация — здесь можно разрешить владельцу и друзьям.
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return response()->json($row);
    }

    /**
     * Создание улова (минимальный набор полей, без привязки к погоде).
     * POST /api/v1/catches
     * Body (JSON):
     * {
     *   "lat": 55.75, "lng": 37.61,
     *   "species": "Щука",
     *   "length": 65.5, "weight": 3.4,
     *   "style": "спиннинг", "lure": "джиг", "tackle": "плетёнка 0.12",
     *   "notes": "на свале", "photo_url": "https://.../photo.jpg",
     *   "caught_at": "2025-08-21 07:30:00",
     *   "privacy": "all"    // all|friends|private
     * }
     */
    public function store(Request $request)
    {
        // Если нет аутентификации — можно использовать фиксированного test user_id или null.
        // При появлении auth — замените на $request->user()->id
        $userId = $request->user()->id ?? null;

        $data = $request->validate([
            'lat'       => ['required', 'numeric'],
            'lng'       => ['required', 'numeric'],
            'species'   => ['nullable', 'string', 'max:255'],
            'length'    => ['nullable', 'numeric'],
            'weight'    => ['nullable', 'numeric'],
            'depth'     => ['nullable', 'numeric'],
            'style'     => ['nullable', 'string', 'max:255'],
            'lure'      => ['nullable', 'string', 'max:255'],
            'tackle'    => ['nullable', 'string', 'max:255'],
            'notes'     => ['nullable', 'string'],
            'photo_url' => ['nullable', 'string', 'max:255'],
            'caught_at' => ['nullable', 'date'],
            'privacy'   => ['required', Rule::in(['all','friends','private'])],
        ]);

        $insert = [
            'user_id'   => $userId,
            'lat'       => $data['lat'],
            'lng'       => $data['lng'],
            'species'   => $data['species']  ?? null,
            'length'    => $data['length']   ?? null,
            'weight'    => $data['weight']   ?? null,
            'depth'     => $data['depth']    ?? null,
            'style'     => $data['style']    ?? null,
            'lure'      => $data['lure']     ?? null,
            'tackle'    => $data['tackle']   ?? null,
            'notes'     => $data['notes']    ?? null,
            'photo_url' => $data['photo_url']?? null,
            'caught_at' => $data['caught_at']?? null,
            'privacy'   => $data['privacy'],
            'created_at'=> now(),
            'updated_at'=> now(),
        ];

        try {
            $id = DB::table('catch_records')->insertGetId($insert);
        } catch (\Throwable $e) {
            \Log::error('CATCH_SAVE_FAIL', ['ex'=>$e, 'payload'=>$insert]);
            return response()->json(['error' => 'save_failed'], 422);
        }

        // Вернём то же представление, что и в show()
        $request->merge(['id' => $id]);
        return $this->show($request, $id);
    }

    /**
     * Возвращает выражение для поля аватарки с учётом наличия столбцов.
     * Приоритет: users.avatar -> users.photo_url -> пустая строка.
     */
    private function userAvatarExpr(): string
    {
        if (Schema::hasColumn('users', 'avatar')) {
            return 'u.avatar';
        }
        if (Schema::hasColumn('users', 'photo_url')) {
            return 'u.photo_url';
        }
        return "''";
    }

    /**
     * Карточки для карты (если используешь маркеры уловов).
     * GET /api/v1/catches/markers?bbox=minLng,minLat,maxLng,maxLat&limit=500
     */
    public function markers(Request $request)
    {
        $limit = (int) $request->integer('limit', 500);

        $q = DB::table('catch_records')->select('id','lat','lng')
              ->where('privacy','=', 'all');

        if ($request->filled('bbox')) {
            [$minLng,$minLat,$maxLng,$maxLat] = array_map('floatval', explode(',', $request->string('bbox')));
            $q->whereBetween('lat', [$minLat,$maxLat])
              ->whereBetween('lng', [$minLng,$maxLng]);
        }

        return response()->json(['items' => $q->orderByDesc('id')->limit($limit)->get()]);
    }
}