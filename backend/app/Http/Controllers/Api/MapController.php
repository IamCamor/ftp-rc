<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\MapPoint;

class MapController extends Controller
{
    // Получить список точек
    public function index()
    {
        return response()->json(MapPoint::all());
    }

    // Добавить точку
    public function store(Request $request)
    {
        $point = MapPoint::create($request->all());
        return response()->json($point, 201);
    }

    // Обновить точку
    public function update(Request $request, $id)
    {
        $point = MapPoint::findOrFail($id);
        $point->update($request->all());
        return response()->json($point);
    }

    // Удалить точку
    public function destroy($id)
    {
        $point = MapPoint::findOrFail($id);
        $point->delete();
        return response()->json(null, 204);
    }
}
