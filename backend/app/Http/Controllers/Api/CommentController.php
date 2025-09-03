<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Services\AIModeration;

class CommentController extends Controller
{
    public function store(Request $request, $catchId)
    {
        $body = trim((string)$request->input('body', ''));
        if ($body === '') {
            return response()->json(['ok' => false, 'error' => 'empty_body'], 422);
        }

        $userId = auth()->id() ?? null; // гостевой режим разрешён: user_id может быть null
        $ai = new AIModeration();
        $mod = $ai->moderateText($body);
        $approved = $mod['ok'] ? 1 : 0;

        $id = DB::table('catch_comments')->insertGetId([
            'catch_id' => (int)$catchId,
            'user_id' => $userId,
            'body' => $body,
            'is_approved' => $approved,
            'meta' => json_encode(['ai' => $mod], JSON_UNESCAPED_UNICODE),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'ok' => true,
            'id' => $id,
            'is_approved' => (bool)$approved,
            'ai' => $mod,
        ], 201);
    }
}
