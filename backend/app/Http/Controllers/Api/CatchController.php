<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CatchController extends Controller
{
    public function show($id)
    {
        $row = DB::table('catch_records as cr')
            ->leftJoin('users as u', 'u.id', '=', 'cr.user_id')
            ->selectRaw("cr.*, u.name AS user_name, COALESCE(u.photo_url,'') AS user_avatar,
                         (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count,
                         (SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id=cr.id AND (cc.is_approved=1 OR cc.is_approved IS NULL)) AS comments_count")
            ->where('cr.id', (int)$id)
            ->first();

        if (!$row) return response()->json(['error' => 'not_found'], 404);

        $comments = DB::table('catch_comments as cc')
            ->leftJoin('users as u', 'u.id', '=', 'cc.user_id')
            ->where('cc.catch_id', (int)$id)
            ->where(function($q){
                $q->where('cc.is_approved', 1)->orWhereNull('cc.is_approved');
            })
            ->orderBy('cc.created_at', 'desc')
            ->limit(100)
            ->get(['cc.id','cc.body','cc.created_at','u.name as user_name','u.id as user_id','u.photo_url as user_avatar']);

        return response()->json(['item' => $row, 'comments' => $comments]);
    }

    public function store(Request $r)
    {
        $data = $r->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
            'species' => 'nullable|string|max:255',
            'length' => 'nullable|numeric',
            'weight' => 'nullable|numeric',
            'style' => 'nullable|string|max:255',
            'lure' => 'nullable|string|max:255',
            'tackle' => 'nullable|string|max:255',
            'privacy' => 'nullable|in:all,friends,private',
            'caught_at' => 'nullable|date',
            'notes' => 'nullable|string',
            'photo_url' => 'nullable|string|max:255',
        ]);

        $data['user_id'] = auth()->id() ?? null;
        $data['created_at'] = now();
        $data['updated_at'] = now();

        // map to DB columns
        $insert = [
            'user_id' => $data['user_id'],
            'lat' => $data['lat'],
            'lng' => $data['lng'],
            'species' => $data['species'] ?? null,
            'length' => $data['length'] ?? null,
            'weight' => $data['weight'] ?? null,
            'style' => $data['style'] ?? null,
            'lure' => $data['lure'] ?? null,
            'tackle' => $data['tackle'] ?? null,
            'privacy' => $data['privacy'] ?? 'all',
            'caught_at' => $data['caught_at'] ?? null,
            'notes' => $data['notes'] ?? null,
            'photo_url' => $data['photo_url'] ?? null,
            'created_at' => $data['created_at'],
            'updated_at' => $data['updated_at'],
        ];

        $id = DB::table('catch_records')->insertGetId($insert);

        return $this->show($id);
    }
}
