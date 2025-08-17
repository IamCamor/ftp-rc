<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CatchRecord;
use App\Models\Media;
use App\Models\CatchLike;
use App\Models\CatchComment;
use App\Models\ModerationItem;

class CatchesController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
            'species' => 'nullable|string|max:255',
            'length' => 'nullable|numeric',
            'weight' => 'nullable|numeric',
            'depth' => 'nullable|numeric',
            'style' => 'nullable|string|max:255',
            'lure' => 'nullable|string|max:255',
            'tackle' => 'nullable|string|max:255',
            'friend_id' => 'nullable|integer',
            'privacy' => 'nullable|string|in:all,friends,groups,none',
        ]);
        $data['user_id'] = auth()->id();
        $rec = CatchRecord::create($data);
        return response()->json($rec, 201);
    }

    public function uploadMedia(Request $request, $id)
    {
        $catch = CatchRecord::findOrFail($id);
        $request->validate(['file' => 'required|file|max:5120']);
        $file = $request->file('file');
        $path = $file->store('catches/'.$catch->id, 'public');
        $media = Media::create([
            'model_type' => CatchRecord::class,
            'model_id'   => $catch->id,
            'disk'       => 'public',
            'path'       => $path,
            'mime'       => $file->getMimeType(),
            'size'       => $file->getSize(),
        ]);
        return response()->json($media, 201);
    }

    public function like($id)
    {
        $userId = auth()->id();
        $like = CatchLike::firstOrCreate(['catch_id' => $id, 'user_id' => $userId]);
        return ['ok' => true, 'liked' => true, 'id' => $like->id];
    }

    public function unlike($id)
    {
        $userId = auth()->id();
        CatchLike::where(['catch_id' => $id, 'user_id' => $userId])->delete();
        return ['ok' => true, 'liked' => false];
    }

    public function comment(Request $request, $id)
    {
        $request->validate(['text' => 'required|string|min:1|max:2000']);
        $comment = CatchComment::create([
            'catch_id' => $id,
            'user_id'  => auth()->id(),
            'text'     => $request->string('text'),
            'status'   => config('features.ai_moderation') ? 'pending' : 'approved',
        ]);
        if (config('features.ai_moderation')) {
            ModerationItem::create([
                'type'     => 'comment',
                'ref_id'   => $comment->id,
                'payload'  => ['text' => $comment->text],
                'provider' => config('ai.provider', 'openai'),
                'status'   => 'pending',
            ]);
            dispatch(new \App\Jobs\ModerateText($comment->id, 'comment'));
        }
        return response()->json($comment, 201);
    }
}
