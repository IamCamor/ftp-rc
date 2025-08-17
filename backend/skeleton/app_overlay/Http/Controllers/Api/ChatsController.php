<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ChatsController extends Controller
{
    // Список чатов пользователя
    public function index()
    {
        return response()->json([
            'rooms' => [], // сюда позже прикрутим реальные данные
        ]);
    }

    // Сообщения конкретного чата
    public function messages($roomId)
    {
        return response()->json([
            'room_id'  => (int) $roomId,
            'messages' => [],
        ]);
    }

    // Отправка сообщения
    public function send(Request $request, $roomId)
    {
        $data = $request->validate([
            'text' => 'required|string|min:1|max:2000',
        ]);

        // Заглушка успеха — без БД, чтобы не падало
        return response()->json([
            'ok'       => true,
            'room_id'  => (int) $roomId,
            'message'  => [
                'id'         => 1,
                'text'       => $data['text'],
                'user_id'    => $request->user()?->id,
                'created_at' => now()->toDateTimeString(),
            ],
        ], 201);
    }
}