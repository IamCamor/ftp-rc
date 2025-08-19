<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Event;
class EventsController extends Controller {
  public function store(Request $r){
    $d=$r->validate(['title'=>'required|string|max:255','region'=>'nullable|string|max:255','starts_at'=>'nullable|date','ends_at'=>'nullable|date','description'=>'nullable|string','location_lat'=>'nullable|numeric','location_lng'=>'nullable|numeric','link'=>'nullable|string|max:255']);
    $d['is_approved']=false; return response()->json(Event::create($d));
  }
  public function uploadPhoto($id, Request $r){
    $r->validate(['file'=>'required|image|max:8192']); $e=Event::findOrFail($id);
    $path=$r->file('file')->store('events','public'); $e->photo_url=asset('storage/'.$path); $e->save();
    return response()->json(['ok'=>true,'photo_url'=>$e->photo_url]);
  }
}
