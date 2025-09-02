<?php
namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use Illuminate\Routing\Controller;

class WeatherLocationsController extends Controller
{
    // Простое хранение в sessions/DB можно заменить на users->weather_cache
    public function index(Request $r)
    {
        // Пример: читаем из таблицы weather_cache или из файла — здесь просто вернём заглушку из сессии
        $items = $r->session()->get('weather_locations', []);
        return response()->json(['items'=>$items]);
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'title'=>'required|string|min:2',
            'lat'=>'required|numeric',
            'lng'=>'required|numeric',
        ]);
        $items = $r->session()->get('weather_locations', []);
        $id = count($items) ? (max(array_column($items,'id'))+1) : 1;
        $items[] = ['id'=>$id, 'title'=>$data['title'], 'lat'=>$data['lat'], 'lng'=>$data['lng']];
        $r->session()->put('weather_locations', $items);
        return response()->json(['ok'=>true, 'id'=>$id], 201);
    }

    public function destroy(Request $r, $id)
    {
        $items = $r->session()->get('weather_locations', []);
        $items = array_values(array_filter($items, fn($x)=> (int)$x['id'] !== (int)$id));
        $r->session()->put('weather_locations', $items);
        return response()->noContent();
    }
}
