<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class UploadController extends Controller
{
    public function store(Request $request)
    {
        $files = $request->file('files', []);
        $single = $request->file('file');
        if ($single) $files[] = $single;

        if (empty($files)) {
            return response()->json(['ok' => false, 'error' => 'no_files'], 422);
        }

        $urls = [];
        foreach ($files as $file) {
            $path = $file->store('public/uploads');
            $urls[] = Storage::url($path);
        }
        return response()->json(['ok' => true, 'urls' => $urls], 201);
    }
}
