<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PointWriteController extends Controller
{
    public function store(Request $r)
    {
        // fishing_points: id,user_id,lat,lng,title,description,category,is_public,is_highlighted,status,created_at,updated_at
        $data = $r->validate([
            'user_id'      => 'nullable|integer|exists:users,id',
            'lat'          => 'required|numeric',
            'lng'          => 'required|numeric',
            'title'        => 'required|string|max:255',
            'description'  => 'nullable|string',
            'category'     => 'required|string|in:spot,shop,slip,camp',
            'is_public'    => 'nullable|boolean',
            'is_highlighted'=> 'nullable|boolean',
            'status'       => 'nullable|string|in:approved,pending,rejected',
        ]);

        $now = now();
        $id = DB::table('fishing_points')->insertGetId([
            'user_id'        => $data['user_id'] ?? null,
            'lat'            => $data['lat'],
            'lng'            => $data['lng'],
            'title'          => $data['title'],
            'description'    => $data['description'] ?? null,
            'category'       => $data['category'],
            'is_public'      => array_key_exists('is_public',$data) ? (int)$data['is_public'] : 1,
            'is_highlighted' => array_key_exists('is_highlighted',$data) ? (int)$data['is_highlighted'] : 0,
            'status'         => $data['status'] ?? 'approved',
            'created_at'     => $now,
            'updated_at'     => $now,
        ]);

        $row = DB::table('fishing_points')->where('id',$id)->first();
        return response()->json($row, 201);
    }

    public function categories()
    {
        return response()->json([
            'items' => ['spot','shop','slip','camp']
        ]);
    }
}
