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
    if ($r->filled('bbox')) {
      [$minLng,$minLat,$maxLng,$maxLat] = array_map('floatval', explode(',',$r->string('bbox')));
      $q->whereBetween('lat', [$minLat,$maxLat])->whereBetween('lng',[$minLng,$maxLng]);
    }
    $q->with('photo');
    return response()->json(['items'=>$q->orderByDesc('id')->limit(1000)->get()]);
  }
  public function store(Request $r){
    $data=$r->validate([
      'title'=>'required|string|min:2',
      'type'=>'required|in:shop,slip,camp,catch,spot',
      'lat'=>'required|numeric','lng'=>'required|numeric',
      'photo_id'=>'nullable|integer'
    ]);
    $data['is_highlighted']=$r->boolean('is_highlighted',false);
    $data['is_approved']=true;
    $p = FishingPoint::create($data);
    return response()->json($p->load('photo'),201);
  }
  public function show($id){ return response()->json(FishingPoint::with('photo')->findOrFail($id)); }
  public function update(Request $r,$id){ $p=FishingPoint::findOrFail($id); $p->fill($r->only(['title','type','lat','lng','is_highlighted','photo_id']))->save(); return response()->json($p->load('photo')); }
  public function destroy($id){ FishingPoint::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
  public function categories(){ return response()->json(['items'=>['shop','slip','camp','catch','spot']]); }
  public function list(){ return response()->json(['items'=>FishingPoint::with('photo')->orderByDesc('id')->paginate(20)]); }
}
