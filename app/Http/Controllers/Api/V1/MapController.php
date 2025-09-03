<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MapController extends Controller
{
    public function icons(Request $request)
    {
        return response()->json(config('map_icons'));
    }

    public function points(Request $request)
    {
        $limit = (int)($request->query('limit', 1000));
        $offset = (int)($request->query('offset', 0));

        $points = DB::table('fishing_points')
            ->select('id','lat','lng','title','description','category','is_highlighted','status')
            ->where('is_public', 1)
            ->where('status', 'approved')
            ->orderByDesc('id')
            ->limit($limit)->offset($offset)
            ->get()
            ->map(function($p){
                return [
                    'id' => (int)$p->id,
                    'type' => $p->category ?? 'spot',
                    'lat' => (float)$p->lat,
                    'lng' => (float)$p->lng,
                    'title' => $p->title ?? '',
                    'descr' => $p->description ?? '',
                    'highlight' => (bool)($p->is_highlighted ?? false),
                    'source' => 'fishing_points',
                ];
            })->toArray();

        $stores = DB::table('stores')
            ->select('id','lat','lng','name','address','category')
            ->whereNotNull('lat')->whereNotNull('lng')
            ->orderByDesc('id')
            ->limit($limit)->offset($offset)
            ->get()
            ->map(function($s){
                return [
                    'id' => (int)$s->id,
                    'type' => $s->category ? strtolower($s->category) : 'store',
                    'lat' => (float)$s->lat,
                    'lng' => (float)$s->lng,
                    'title' => $s->name ?? '',
                    'descr' => $s->address ?? '',
                    'highlight' => false,
                    'source' => 'stores',
                ];
            })->toArray();

        $events = DB::table('events')
            ->select('id','title','location_lat','location_lng','region','starts_at','ends_at')
            ->whereNotNull('location_lat')->whereNotNull('location_lng')
            ->orderByDesc('starts_at')
            ->limit($limit)->offset($offset)
            ->get()
            ->map(function($e){
                return [
                    'id' => (int)$e->id,
                    'type' => 'event',
                    'lat' => (float)$e->location_lat,
                    'lng' => (float)$e->location_lng,
                    'title' => $e->title ?? '',
                    'descr' => trim(($e->region ?? '').' '.($e->starts_at ?? '')),
                    'highlight' => false,
                    'source' => 'events',
                ];
            })->toArray();

        return response()->json([
            'items' => array_values(array_merge($points, $stores, $events)),
        ]);
    }
}
