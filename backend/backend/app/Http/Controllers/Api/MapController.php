<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Eloquent\Builder;
use App\Models\FishingPoint;

class MapController extends Controller
{
    /**
     * GET /api/v1/map/points
     * Параметры:
     *  - bbox=MINLNG,MINLAT,MAXLNG,MAXLAT (опц.)
     *  - filter=spot|shop|slip|camp|catch (опц.)
     *  - limit (опц., по умолчанию 500, макс 2000)
     *  - page (опц., если включить paginate=true)
     *  - paginate=true|false (опц., по умолчанию false — простой массив)
     */
    public function index(Request $request)
    {
        $q = FishingPoint::query();

        // Безопасная фильтрация по модерации — только если колонка существует
        $requireApproval = (bool) config('app.points_require_approval', true);
        if ($requireApproval && Schema::hasColumn('fishing_points', 'is_approved')) {
            $q->where('is_approved', 1);
        }

        // Фильтр по типу — только если колонка type есть
        if ($request->filled('filter') && Schema::hasColumn('fishing_points', 'type')) {
            $q->where('type', $request->string('filter'));
        }

        // bbox: "minLng,minLat,maxLng,maxLat"
        if ($request->filled('bbox')) {
            $parts = explode(',', (string) $request->query('bbox'));
            if (count($parts) === 4) {
                [$minLng, $minLat, $maxLng, $maxLat] = array_map('floatval', $parts);
                // Колонки lat/lng должны существовать в любой нашей схеме — но всё равно проверим
                if (Schema::hasColumn('fishing_points', 'lat') && Schema::hasColumn('fishing_points', 'lng')) {
                    $q->whereBetween('lat', [$minLat, $maxLat])
                      ->whereBetween('lng', [$minLng, $maxLng]);
                }
            }
        }

        // Жадная подгрузка фото (если в модели настроена связь photo -> Media)
        $q->with('photo');

        // Сортировка по новизне (если нет id — Laravel всё равно выполнит ORDER BY id DESC без падения)
        $q->orderByDesc('id');

        // Пагинация/лимит
        $paginate = filter_var($request->query('paginate', false), FILTER_VALIDATE_BOOL);
        $limit = (int) $request->query('limit', 500);
        $limit = max(1, min($limit, 2000));

        if ($paginate) {
            $items = $q->paginate(min($limit, 100)); // разумная страница
            return response()->json([
                'items' => $items->items(),
                'meta'  => [
                    'current_page' => $items->currentPage(),
                    'per_page'     => $items->perPage(),
                    'total'        => $items->total(),
                    'last_page'    => $items->lastPage(),
                ],
            ]);
        }

        $items = $q->limit($limit)->get();

        return response()->json(['items' => $items]);
    }

    /**
     * POST /api/v1/map/points
     * Создание точки — поля, которых нет в БД, тихо проигнорируются Eloquent-ом.
     */
    public function store(Request $request)
    {
        // Валидируем базовые поля, которые точно есть
        $data = $request->validate([
            'title' => 'required|string|min:2',
            'lat'   => 'required|numeric',
            'lng'   => 'required|numeric',
            // Необязательные:
            'type'        => 'nullable|string',      // если колонки нет — Eloquent просто не сохранит
            'photo_id'    => 'nullable|integer',
            'is_approved' => 'nullable|boolean',
            'is_highlighted' => 'nullable|boolean',
        ]);

        // Значения по умолчанию — даже если колонок нет, Eloquent их проигнорирует
        $data['is_approved']    = $request->boolean('is_approved', true);
        $data['is_highlighted'] = $request->boolean('is_highlighted', false);

        $point = new FishingPoint();
        // Заполняем ТОЛЬКО существующие в таблице поля, чтобы не ловить SQL-ошибки
        $fillable = collect($data)->filter(function ($_, $key) {
            return Schema::hasColumn('fishing_points', $key);
        })->all();

        $point->fill($fillable);
        $point->save();

        return response()->json($point->load('photo'), 201);
    }

    /**
     * GET /api/v1/map/points/{id}
     */
    public function show(int $id)
    {
        $p = FishingPoint::with('photo')->findOrFail($id);
        return response()->json($p);
    }

    /**
     * PUT /api/v1/map/points/{id}
     */
    public function update(Request $request, int $id)
    {
        $p = FishingPoint::findOrFail($id);

        $payload = $request->only([
            'title','type','lat','lng','is_highlighted','is_approved','photo_id'
        ]);

        // Фильтруем по реально существующим колонкам
        $safe = collect($payload)->filter(function ($_, $key) {
            return Schema::hasColumn('fishing_points', $key);
        })->all();

        $p->fill($safe)->save();

        return response()->json($p->load('photo'));
    }

    /**
     * DELETE /api/v1/map/points/{id}
     */
    public function destroy(int $id)
    {
        FishingPoint::whereKey($id)->delete();
        return response()->json(['ok' => true]);
    }

    /**
     * GET /api/v1/map/categories
     * Возвращаем статический список типов (фронту полезно для фильтров).
     * Это НЕ зависит от наличия колонки type.
     */
    public function categories()
    {
        return response()->json(['items' => ['spot','shop','slip','camp','catch']]);
    }

    /**
     * GET /api/v1/map/list
     * Пагинированный список точек (для админки/списков).
     */
    public function list(Request $request)
    {
        $q = FishingPoint::query()->with('photo')->orderByDesc('id');
        $per = max(1, min((int)$request->query('per', 20), 100));
        $items = $q->paginate($per);

        return response()->json([
            'items' => $items->items(),
            'meta'  => [
                'current_page' => $items->currentPage(),
                'per_page'     => $items->perPage(),
                'total'        => $items->total(),
                'last_page'    => $items->lastPage(),
            ],
        ]);
    }
}
