<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\FishingPoint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class MapController extends Controller
{
    /** GET /api/v1/map/points (ваш index) */
    public function index(Request $r)
    {
        $q = FishingPoint::query();

        // Безопасные фильтры по доступности
        if ($this->has('fishing_points', 'status')) {
            $q->where('status', 'approved');
        }
        if ($this->has('fishing_points', 'is_public')) {
            $q->where('is_public', 1);
        }
        // старый флаг is_approved — если колонка есть
        if ($this->has('fishing_points', 'is_approved')) {
            $q->where('is_approved', true);
        }

        // Категория: принимаем и category, и filter
        $category = $r->query('category', $r->query('filter'));
        $allowed  = ['spot','catch','shop','slip','camp'];
        if ($category !== null && $category !== '') {
            if (!in_array($category, $allowed, true)) {
                return response()->json(['error'=>'invalid_category','allowed'=>$allowed], 400);
            }
            $q->where('category', $category);
        }

        // Поиск по названию/описанию
        if ($r->filled('q')) {
            $term = trim($r->string('q'));
            $q->where(function($w) use ($term) {
                $w->where('title', 'like', "%{$term}%")
                  ->orWhere('description', 'like', "%{$term}%");
            });
        }

        // BBOX: lng1,lat1,lng2,lat2
        if ($r->filled('bbox')) {
            $parts = array_map('floatval', explode(',', $r->string('bbox')));
            if (count($parts) === 4) {
                [$minLng, $minLat, $maxLng, $maxLat] = $parts;
                $q->whereBetween('lat', [$minLat, $maxLat])
                  ->whereBetween('lng', [$minLng, $maxLng]);
            }
        }

        // Вложенная фото-связь, если модель её поддерживает
        $q->with('photo');

        $limit = min((int) $r->query('limit', 500), 1000);

        return response()->json([
            'items' => $q->orderByDesc('id')->limit($limit)->get()
        ]);
    }

    /** POST /api/v1/map/points */
    public function store(Request $r)
    {
        $allowed = ['spot','catch','shop','slip','camp'];

        $data = $r->validate([
            'title'       => 'required|string|min:2',
            'category'    => 'required|in:' . implode(',', $allowed),
            'lat'         => 'required|numeric',
            'lng'         => 'required|numeric',
            'description' => 'nullable|string',
            'photo_id'    => 'nullable|integer',
            'is_highlighted' => 'sometimes|boolean',
        ]);

        // безопасные дефолты под фактические колонки
        if ($this->has('fishing_points', 'status')) {
            $data['status'] = 'approved';
        }
        if ($this->has('fishing_points', 'is_public')) {
            $data['is_public'] = 1;
        }
        if ($this->has('fishing_points', 'is_highlighted')) {
            $data['is_highlighted'] = (bool)($data['is_highlighted'] ?? false);
        }

        $p = FishingPoint::create($data);

        return response()->json($p->load('photo'), 201);
    }

    /** GET /api/v1/map/points/{id} */
    public function show($id)
    {
        return response()->json(
            FishingPoint::with('photo')->findOrFail($id)
        );
    }

    /** PATCH/PUT /api/v1/map/points/{id} */
    public function update(Request $r, $id)
    {
        $p = FishingPoint::findOrFail($id);

        $allowed = ['spot','catch','shop','slip','camp'];

        $data = $r->validate([
            'title'       => 'sometimes|string|min:2',
            'category'    => 'sometimes|in:' . implode(',', $allowed),
            'lat'         => 'sometimes|numeric',
            'lng'         => 'sometimes|numeric',
            'description' => 'sometimes|nullable|string',
            'photo_id'    => 'sometimes|nullable|integer',
            'is_highlighted' => 'sometimes|boolean',
        ]);

        // Не трогаем несущ. колонки (Laravel сам их игнорит, но подстрахуемся)
        if (!$this->has('fishing_points', 'is_highlighted')) {
            unset($data['is_highlighted']);
        }

        $p->fill($data)->save();

        return response()->json($p->load('photo'));
    }

    /** DELETE /api/v1/map/points/{id} */
    public function destroy($id)
    {
        FishingPoint::whereKey($id)->delete();
        return response()->json(['ok' => true]);
    }

    /** GET /api/v1/map/categories */
    public function categories()
    {
        return response()->json([
            'items' => ['spot','catch','shop','slip','camp']
        ]);
    }

    /** GET /api/v1/map/points/list (постранично) */
    public function list()
    {
        return response()->json([
            'items' => FishingPoint::with('photo')->orderByDesc('id')->paginate(20)
        ]);
    }

    /** Проверка существования колонки в таблице */
    private function has(string $table, string $column): bool
    {
        try {
            return Schema::hasColumn($table, $column);
        } catch (\Throwable $e) {
            return false;
        }
    }
}