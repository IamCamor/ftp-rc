<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CatchWriteController extends Controller
{
    public function store(Request $r)
    {
        // Валидация под вашу таблицу catch_records
        $data = $r->validate([
            'user_id'   => 'nullable|integer|exists:users,id',
            'lat'       => 'required|numeric',
            'lng'       => 'required|numeric',
            'species'   => 'nullable|string|max:255',
            'length'    => 'nullable|numeric',
            'weight'    => 'nullable|numeric',
            'depth'     => 'nullable|numeric',
            'style'     => 'nullable|string|max:255',
            'lure'      => 'nullable|string|max:255',
            'tackle'    => 'nullable|string|max:255',
            'privacy'   => 'nullable|string|in:all,public,everyone,friends,private',
            'caught_at' => 'nullable|date',
            'water_type'=> 'nullable|string|max:255',
            'water_temp'=> 'nullable|numeric',
            'wind_speed'=> 'nullable|numeric',
            'pressure'  => 'nullable|numeric',
            'companions'=> 'nullable|string|max:255',
            'notes'     => 'nullable|string',
            'photo_url' => 'nullable|string|max:255',
        ]);

        $data['privacy'] = $data['privacy'] ?? 'all';
        $now = now();

        $id = DB::table('catch_records')->insertGetId([
            'user_id'    => $data['user_id']   ?? null,
            'lat'        => $data['lat'],
            'lng'        => $data['lng'],
            'species'    => $data['species']   ?? null,
            'length'     => $data['length']    ?? null,
            'weight'     => $data['weight']    ?? null,
            'depth'      => $data['depth']     ?? null,
            'style'      => $data['style']     ?? null,
            'lure'       => $data['lure']      ?? null,
            'tackle'     => $data['tackle']    ?? null,
            'privacy'    => $data['privacy'],
            'caught_at'  => $data['caught_at'] ?? null,
            'water_type' => $data['water_type']?? null,
            'water_temp' => $data['water_temp']?? null,
            'wind_speed' => $data['wind_speed']?? null,
            'pressure'   => $data['pressure']  ?? null,
            'companions' => $data['companions']?? null,
            'notes'      => $data['notes']     ?? null,
            'photo_url'  => $data['photo_url'] ?? null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $row = DB::table('catch_records')->where('id', $id)->first();
        return response()->json($row, 201);
    }
}
