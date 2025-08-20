<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Club;

class ClubsController extends Controller {
  public function index(){ return response()->json(['items'=>Club::orderByDesc('id')->limit(300)->get()]); }
  public function store(Request $r){
    $data=$r->validate(['name'=>'required|min:2','logo'=>'nullable','description'=>'nullable']);
    return response()->json(Club::create($data),201);
  }
  public function show($id){ return response()->json(Club::findOrFail($id)); }
  public function update(Request $r,$id){ $c=Club::findOrFail($id); $c->fill($r->only('name','logo','description'))->save(); return response()->json($c); }
  public function destroy($id){ Club::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
}
