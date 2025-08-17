<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Event;
class AdminEventsController extends Controller{
  public function index(){ $events=Event::orderBy('starts_at','desc')->paginate(20); return view('admin.events.index', compact('events')); }
  public function store(Request $r){ $data=$r->validate(['title'=>'required|string|max:255','description'=>'nullable|string','starts_at'=>'required|date','ends_at'=>'nullable|date|after_or_equal:starts_at','region'=>'nullable|string|max:255']); Event::create($data+['creator_id'=>auth()->id()]); return back(); }
  public function destroy($id){ Event::where('id',$id)->delete(); return back(); }
}
