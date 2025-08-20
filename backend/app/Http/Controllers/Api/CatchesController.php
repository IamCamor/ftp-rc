<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CatchRecord;

class CatchesController extends Controller {
  public function index(Request $r){
    $q = CatchRecord::query();
    // публично показываем только privacy in ['all'] (без авторизации)
    $q->where('privacy','all');
    if ($r->filled('near')){
      [$lat,$lng] = array_map('floatval', explode(',',$r->string('near'))); // "lat,lng"
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
      'style'=>'in:shore,boat,ice','privacy'=>'in:all,friends,groups,none'
    ]);
    $data['style'] = $data['style'] ?? 'shore';
    $data['privacy'] = $data['privacy'] ?? 'all';
    return response()->json(CatchRecord::create($data),201);
  }
  public function show($id){ return response()->json(CatchRecord::findOrFail($id)); }
  public function update(Request $r,$id){ $c=CatchRecord::findOrFail($id); $c->fill($r->all())->save(); return response()->json($c); }
  public function destroy($id){ CatchRecord::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
}
