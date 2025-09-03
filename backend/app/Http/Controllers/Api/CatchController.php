<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class CatchController extends Controller
{
    public function show($id)
    {
        $row = DB::table('catch_records as cr')
            ->leftJoin('users as u', 'u.id', '=', 'cr.user_id')
            ->select([
                'cr.*',
                DB::raw('u.name AS user_name'),
                DB::raw('(SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count'),
                DB::raw('(SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id=cr.id AND (cc.is_approved=1 OR cc.is_approved IS NULL)) AS comments_count'),
            ])
            ->where('cr.id', (int)$id)
            ->first();

        if (!$row) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $row->user_avatar = config('ui.default_avatar', '');
        $row->liked_by_me = 0;

        return response()->json($row);
    }

    public function store(Request $r)
    {
        // простая валидация
        $v = Validator::make($r->all(), [
            'species'   => 'nullable|string|max:255',
            'length'    => 'nullable|numeric',
            'weight'    => 'nullable|numeric',
            'lat'       => 'required|numeric',
            'lng'       => 'required|numeric',
            'style'     => 'nullable|string|max:255',
            'lure'      => 'nullable|string|max:255',
            'tackle'    => 'nullable|string|max:255',
            'privacy'   => 'nullable|in:public,friends,private',
            'caught_at' => 'nullable|date',
            'notes'     => 'nullable|string',
            'photo_url' => 'nullable|string|max:255',
        ]);

        if ($v->fails()) {
            return response()->json(['errors' => $v->errors()], 422);
        }

        $data = $v->validated();
        $data['privacy'] = $data['privacy'] ?? 'public';
        $data['created_at'] = now();
        $data['updated_at'] = now();
        $data['user_id'] = auth()->id(); // может быть null (гость — если разрешено)

        $id = DB::table('catch_records')->insertGetId($data);

        // Возвращаем с теми же полями, что и show()
        return $this->show($id);
    }
}