<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\FishingPoint;
class MapController extends Controller {
  public function index(Request $r){
    $q=FishingPoint::query()->where('is_approved',true);
    if($r->filled('category') && $r->category!=='all'){ $q->where('category',$r->category); }
    return response()->json($q->orderByDesc('id')->limit(500)->get());
  }
  public function store(Request $r){
    $d=$r->validate(['title'=>'required|string|max:255','description'=>'nullable|string','category'=>'required|string|in:spot,shop,slip,resort','lat'=>'required|numeric','lng'=>'required|numeric','is_public'=>'boolean']);
    $d['is_highlighted']=false; $d['is_approved']=false; $p=FishingPoint::create($d); return response()->json($p);
  }
  public function uploadPhoto($id, Request $r){
    $r->validate(['file'=>'required|image|max:5120']); $p=FishingPoint::findOrFail($id);
    $path=$r->file('file')->store('points','public'); $p->photo_url=asset('storage/'.$path); $p->save();
    return response()->json(['ok'=>true,'photo_url'=>$p->photo_url]);
  }
}
