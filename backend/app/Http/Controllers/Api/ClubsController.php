<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Club;
use App\Models\ClubMember;

class ClubsController extends Controller {
  public function index(){ return Club::withCount('members')->paginate(20); }
  public function store(Request $r){
    $data = $r->validate(['name'=>'required|string|max:255','description'=>'nullable|string']);
    $club = Club::create($data + ['owner_id'=>auth()->id()]);
    ClubMember::create(['club_id'=>$club->id,'user_id'=>auth()->id(),'role'=>'admin']);
    return response()->json($club,201);
  }
  public function show($id){ return Club::with('members')->findOrFail($id); }
  public function join($id){ ClubMember::firstOrCreate(['club_id'=>$id,'user_id'=>auth()->id()]); return ['ok'=>true]; }
  public function leave($id){ ClubMember::where(['club_id'=>$id,'user_id'=>auth()->id()])->delete(); return ['ok'=>true]; }
}