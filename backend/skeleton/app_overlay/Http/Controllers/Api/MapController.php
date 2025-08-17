<?php
namespace App\Http\Controllers\Api; use Illuminate\Http\Request; use Illuminate\Routing\Controller as BaseController; use App\Models\MapPoint;
class MapController extends BaseController {
  public function index(){ return MapPoint::latest()->limit(500)->get(); }
  public function store(Request $r){ $d=$r->validate(['title'=>'required','lat'=>'required|numeric','lng'=>'required|numeric','type'=>'string']); return MapPoint::create($d+['visibility'=>'public','is_featured'=>false]); }
  public function share($id){ return ['id'=>$id,'shared'=>true]; }
  public function feature($id){ $p=MapPoint::findOrFail($id); $p->is_featured=true; $p->save(); return $p; }
}