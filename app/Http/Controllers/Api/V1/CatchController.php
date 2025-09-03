<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCatchRequest;
use App\Http\Resources\CatchResource;
use Illuminate\Support\Facades\DB;

class CatchController extends Controller
{
    public function store(StoreCatchRequest $request)
    {
        $userId = $request->user()->id;

        $photoPath = $request->input('photo_url');
        if ($request->hasFile('photo')) {
            $photoPath = $request->file('photo')->store('catches', 'public');
        }

        $id = DB::table('catch_records')->insertGetId([
            'user_id' => $userId,
            'lat' => $request->float('lat'),
            'lng' => $request->float('lng'),
            'species' => $request->input('species'),
            'length' => $request->input('length'),
            'weight' => $request->input('weight'),
            'depth' => $request->input('depth'),
            'style' => $request->input('style'),
            'lure' => $request->input('lure'),
            'tackle' => $request->input('tackle'),
            'privacy' => $request->input('privacy', 'all'),
            'caught_at' => $request->input('caught_at'),
            'water_type' => $request->input('water_type'),
            'water_temp' => $request->input('water_temp'),
            'wind_speed' => $request->input('wind_speed'),
            'pressure' => $request->input('pressure'),
            'companions' => $request->input('companions'),
            'notes' => $request->input('notes'),
            'photo_url' => $photoPath,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $row = DB::table('catch_records as cr')
            ->leftJoin('users as u','u.id','=','cr.user_id')
            ->where('cr.id',$id)
            ->selectRaw("
                cr.*, 
                u.name as user_name, 
                u.avatar_path as user_avatar_path,
                (SELECT COUNT(*) FROM catch_likes cl WHERE cl.catch_id=cr.id) AS likes_count,
                (SELECT COUNT(*) FROM catch_comments cc WHERE cc.catch_id=cr.id AND (cc.is_approved=1 OR cc.is_approved IS NULL)) AS comments_count
            ")->first();

        return (new CatchResource($row))->response()->setStatusCode(201);
    }
}
