<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CatchRecord;

class FeedController extends Controller
{
    public function global(Request $request)
    {
        $q = CatchRecord::query()->latest()->withCount('likes')->with('media');
        return $q->paginate(20);
    }

    public function local(Request $request)
    {
        $request->validate(['near' => 'required']);
        [$lat,$lng,$km] = array_map('floatval', explode(',', $request->string('near')));
        $d = $km/111.0;
        $q = CatchRecord::whereBetween('lat',[$lat-$d,$lat+$d])
                        ->whereBetween('lng',[$lng-$d,$lng+$d])
                        ->latest()->withCount('likes');
        return $q->paginate(20);
    }

    public function follow(Request $request)
    {
        return $this->global($request);
    }
}
