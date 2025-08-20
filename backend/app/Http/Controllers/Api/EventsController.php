<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Event;

class EventsController extends Controller {
  public function index(Request $r){
    $q=Event::query();
    if ($r->filled('region')) $q->where('region',$r->string('region'));
    if ($r->boolean('upcoming',false)) $q->where('starts_at','>=',now());
    $q->orderBy('starts_at','asc');
    return response()->json(['items'=>$q->limit(300)->get()]);
  }
  public function store(Request $r){
    $data=$r->validate(['title'=>'required','description'=>'nullable','starts_at'=>'required|date','ends_at'=>'nullable|date','region'=>'nullable|string']);
    return response()->json(Event::create($data),201);
  }
  public function show($id){ return response()->json(Event::findOrFail($id)); }
  public function update(Request $r,$id){ $e=Event::findOrFail($id); $e->fill($r->all())->save(); return response()->json($e); }
  public function destroy($id){ Event::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
  public function byClub($clubId){ return response()->json(['items'=>Event::where('creator_id',$clubId)->orderBy('starts_at')->get()]); }
}
