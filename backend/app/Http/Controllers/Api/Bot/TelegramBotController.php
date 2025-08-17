<?php

namespace App\Http\Controllers\Api\Bot;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TelegramBotController extends Controller
{
    public function webhook(Request $r)
    {
        return response()->json(['ok'=>true]);
    }
}
