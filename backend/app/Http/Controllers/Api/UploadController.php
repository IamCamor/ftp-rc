<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class UploadController extends Controller
{
    public function store(Request $r)
    {
        $r->validate([
            'file' => 'required|file|max:' . (int) env('FILES_UPLOAD_MAX', 10485760), // 10MB default
        ]);
        $file = $r->file('file');
        $ext  = strtolower($file->getClientOriginalExtension());
        $isVideo = in_array($ext, ['mp4','mov','webm','mkv']);
        $path = $file->store($isVideo ? 'uploads/videos' : 'uploads/photos', 'public');
        return response()->json([
            'ok' => true,
            'url' => Storage::disk('public')->url($path),
            'type' => $isVideo ? 'video' : 'image',
        ]);
    }
}
