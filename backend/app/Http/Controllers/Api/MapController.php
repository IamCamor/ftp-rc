<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\FishingPoint;
use Illuminate\Support\Facades\Schema;

class MapController extends Controller {
  public function index(Request $r){
    $q = FishingPoint::query();
    if (Schema::hasColumn('fishing_points','is_approved')) $q->where('is_approved',true);
    if ($r->filled('filter')) $q->where('type',$r->string('filter'));
    if ($r->filled('bbox')) { // bbox: "minLng,minLat,maxLng,maxLat"
      [$minLng,$minLat,$maxLng,$maxLat] = array_map('floatval', explode(',',$r->string('bbox')));
      $q->whereBetween('lat', [$minLat,$maxLat])->whereBetween('lng',[$minLng,$maxLng]);
    }
    return response()->json(['items'=>$q->orderByDesc('id')->limit(1000)->get()]);
  }
  public function store(Request $r){
    $data=$r->validate(['title'=>'required','type'=>'required','lat'=>'required|numeric','lng'=>'required|numeric']);
    $data['is_highlighted']=$r->boolean('is_highlighted',false);
    $data['is_approved']=true;
    return response()->json(FishingPoint::create($data),201);
  }
  public function show($id){ return response()->json(FishingPoint::findOrFail($id)); }
  public function update(Request $r,$id){ $p=FishingPoint::findOrFail($id); $p->fill($r->all())->save(); return response()->json($p); }
  public function destroy($id){ FishingPoint::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
  public function categories(){ return response()->json(['items'=>['shop','slip','camp','catch','spot']]); }
  public function list(){ return response()->json(['items'=>FishingPoint::orderByDesc('id')->paginate(20)]); }
}
