<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class PointsController extends Controller
{
    /** GET /api/v1/map/points или /api/v1/points (как у вас заведено) */
    public function index(Request $r)
    {
        $limit = (int) $r->query('limit', 500);
        $limit = max(1, min($limit, 1000));

        $q = DB::table('fishing_points')->select([
            'id','user_id','lat','lng','title','description',
            'category','is_public','is_highlighted','status',
            'created_at','updated_at'
        ]);

        // Только одобренные публичные точки для гостей
        $q->where('status', 'approved')->where('is_public', 1);

        // Фильтр по категории (spot|shop|slip|camp)
        if ($r->filled('filter')) {
            $cat = (string)$r->query('filter');
            $allowed = ['spot','shop','slip','camp'];
            if (in_array($cat, $allowed, true)) {
                $q->where('category', $cat);
            }
        }

        // BBOX: minLng,minLat,maxLng,maxLat
        if ($r->filled('bbox')) {
            $parts = explode(',', (string)$r->query('bbox'));
            if (count($parts) === 4) {
                [$minLng,$minLat,$maxLng,$maxLat] = array_map('floatval', $parts);
                $q->whereBetween('lat', [$minLat, $maxLat])
                  ->whereBetween('lng', [$minLng, $maxLng]);
            }
        }

        $items = $q->orderByDesc('id')->limit($limit)->get();

        return response()->json(['items' => $items], 200);
    }

    /** POST /api/v1/points — создание точки */
    public function store(Request $r)
    {
        // ВАЖНО: таблица fishing_points НЕ имеет столбца type/is_approved
        $data = $r->validate([
            'title'        => 'required|string|min:2|max:255',
            'description'  => 'nullable|string',
            'lat'          => 'required|numeric',
            'lng'          => 'required|numeric',
            'category'     => 'required|string|in:spot,shop,slip,camp',
            'is_public'    => 'sometimes|boolean',
            'is_highlighted' => 'sometimes|boolean',
        ]);

        $userId = Auth::id(); // null для гостя — допустимо, поле user_id nullable по вашей схеме
        $isPublic = (bool)($data['is_public'] ?? true);
        $isHighlighted = (bool)($data['is_highlighted'] ?? false);

        // Если нужна премодерация — поменяйте на 'pending'
        $status = 'approved';

        $id = DB::table('fishing_points')->insertGetId([
            'user_id'        => $userId,
            'lat'            => (float)$data['lat'],
            'lng'            => (float)$data['lng'],
            'title'          => $data['title'],
            'description'    => $data['description'] ?? null,
            'category'       => $data['category'],
            'is_public'      => $isPublic ? 1 : 0,
            'is_highlighted' => $isHighlighted ? 1 : 0,
            'status'         => $status,
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        $point = DB::table('fishing_points')->where('id', $id)->first();

        return response()->json($point, 201);
    }

    /** GET /api/v1/points/categories */
    public function categories()
    {
        return response()->json([
            'items' => ['spot', 'shop', 'slip', 'camp']
        ]);
    }

    /** GET /api/v1/points/me (под auth:sanctum) */
    public function me(Request $r)
    {
        $uid = Auth::id();
        if (!$uid) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }

        $items = DB::table('fishing_points')
            ->where('user_id', $uid)
            ->orderByDesc('id')
            ->limit(500)
            ->get();

        return response()->json(['items' => $items]);
    }

    /** GET /api/v1/points/ledger (заготовка чтобы маршрут не падал) */
    public function ledger()
    {
        // Если пока нет таблицы с начислениями — вернём пусто
        return response()->json(['items' => []]);
    }
}