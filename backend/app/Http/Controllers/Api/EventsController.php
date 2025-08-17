<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Event;
use App\Models\EventSubscription;

class EventsController extends Controller {
  public function index(Request $r){
    $q = Event::query();
    if ($r->filled('region')) $q->where('region',$r->string('region'));
    if ($r->filled('from')) $q->whereDate('starts_at','>=',$r->date('from'));
    if ($r->filled('to')) $q->whereDate('starts_at','<=',$r->date('to'));
    return $q->orderBy('starts_at','asc')->paginate(20);
  }
  public function store(Request $r){
    $data = $r->validate([
      'title'=>'required|string|max:255','description'=>'nullable|string',
      'starts_at'=>'required|date','ends_at'=>'nullable|date|after_or_equal:starts_at',
      'region'=>'nullable|string|max:255'
    ]);
    $ev = Event::create($data + ['creator_id'=>auth()->id()]);
    return response()->json($ev,201);
  }
  public function subscribe($id){
    EventSubscription::firstOrCreate(['event_id'=>$id,'user_id'=>auth()->id()]);
    return ['ok'=>true];
  }
  public function unsubscribe($id){
    EventSubscription::where(['event_id'=>$id,'user_id'=>auth()->id()])->delete();
    return ['ok'=>true];
  }
}