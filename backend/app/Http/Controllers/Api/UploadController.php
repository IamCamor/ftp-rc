<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class UploadController extends Controller
{
    public function store(Request $r)
    {
        $r->validate(['file'=>'required|file|max:'.(int)env('FILES_UPLOAD_MAX',10485760)]);
        $f = $r->file('file');
        $ext = strtolower($f->getClientOriginalExtension());
        $isVideo = in_array($ext,['mp4','mov','webm','mkv']);
        $path = $f->store($isVideo?'uploads/videos':'uploads/photos','public');
        return response()->json([
            'ok'=>true,
            'url'=>Storage::disk('public')->url($path),
            'type'=>$isVideo?'video':'image'
        ]);
    }
}
