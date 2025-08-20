<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Media;

class UploadController extends Controller {
  public function image(Request $r){
    $r->validate(['file'=>'required|file|mimes:jpg,jpeg,png,webp|max:8192']);
    $file = $r->file('file');
    $path = $file->store('uploads', 'public'); // storage/app/public/uploads/...
    $url  = Storage::disk('public')->url($path);
    $m = Media::create([
      'disk'=>'public','path'=>$path,'url'=>$url,
      'type'=>$file->getClientMimeType(),'size'=>$file->getSize(),'meta'=>['original'=>$file->getClientOriginalName()],
    ]);
    return response()->json($m,201);
  }
}
