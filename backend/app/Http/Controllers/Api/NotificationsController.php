<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class NotificationsController extends Controller
{
    public function index()
    {
        $items = DB::table('notifications')->where('user_id',1)->orderByDesc('id')->limit(100)->get();
        return response()->json($items);
    }
}
