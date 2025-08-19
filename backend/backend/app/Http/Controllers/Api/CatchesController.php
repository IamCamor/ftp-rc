<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CatchRecord;
use App\Models\CatchMedia;
class CatchesController extends Controller {
  public function store(Request $r){
    $d=$r->validate(['lat'=>'nullable|numeric','lng'=>'nullable|numeric','species'=>'nullable|string|max:255','length'=>'nullable|numeric','weight'=>'nullable|numeric','depth'=>'nullable|numeric','style'=>'nullable|string|max:50','lure'=>'nullable|string|max:255','tackle'=>'nullable|string|max:255','privacy'=>'nullable|string|max:20','companions'=>'nullable|string|max:255','notes'=>'nullable|string','caught_at'=>'nullable|date']);
    $d['is_approved']=false; return response()->json(CatchRecord::create($d));
  }
  public function uploadMedia($id, Request $r){
    $r->validate(['file'=>'required|image|max:8192']); $rec=CatchRecord::findOrFail($id);
    $path=$r->file('file')->store('catches','public'); $url=asset('storage/'.$path);
    CatchMedia::create(['catch_id'=>$rec->id,'url'=>$url,'type'=>'image']); return response()->json(['ok'=>true,'url'=>$url]);
  }
}
