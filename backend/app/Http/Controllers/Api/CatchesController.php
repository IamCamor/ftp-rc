<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CatchRecord;

class CatchesController extends Controller {
  public function index(Request $r){
    $q = CatchRecord::query()->where('privacy','all')->with('photo');
    if ($r->filled('near')){
      [$lat,$lng] = array_map('floatval', explode(',',$r->string('near')));
      $q->orderByRaw('(abs(lat-?)+abs(lng-?)) asc', [$lat,$lng]);
    } else {
      $q->orderByDesc('id');
    }
    return response()->json(['items'=>$q->limit(200)->get()]);
  }
  public function store(Request $r){
    $data = $r->validate([
      'lat'=>'required|numeric','lng'=>'required|numeric',
      'fish'=>'required|string','weight'=>'nullable|numeric','length'=>'nullable|numeric',
      'style'=>'nullable|in:shore,boat,ice','privacy'=>'nullable|in:all,friends,groups,none',
      'photo_id'=>'nullable|integer'
    ]);
    $data['style'] = $data['style'] ?? 'shore';
    $data['privacy'] = $data['privacy'] ?? 'all';
    $c = CatchRecord::create($data);
    return response()->json($c->load('photo'),201);
  }
  public function show($id){ return response()->json(CatchRecord::with('photo')->findOrFail($id)); }
  public function update(Request $r,$id){ $c=CatchRecord::findOrFail($id); $c->fill($r->only(['lat','lng','fish','weight','length','style','privacy','photo_id']))->save(); return response()->json($c->load('photo')); }
  public function destroy($id){ CatchRecord::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
}
