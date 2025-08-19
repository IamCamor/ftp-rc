<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Club;
class ClubsController extends Controller {
  public function store(Request $r){
    $d=$r->validate(['name'=>'required|string|max:255','region'=>'nullable|string|max:255','description'=>'nullable|string']);
    $d['is_approved']=false; return response()->json(Club::create($d));
  }
  public function uploadLogo($id, Request $r){
    $r->validate(['file'=>'required|image|max:4096']); $c=Club::findOrFail($id);
    $path=$r->file('file')->store('clubs','public'); $c->logo_url=asset('storage/'.$path); $c->save();
    return response()->json(['ok'=>true,'logo_url'=>$c->logo_url]);
  }
}
