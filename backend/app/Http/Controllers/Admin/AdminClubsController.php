<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use App\Models\Club;
use App\Models\ClubMember;
class AdminClubsController extends Controller{
  public function index(){ $clubs=Club::withCount('members')->orderBy('created_at','desc')->paginate(20); return view('admin.clubs.index', compact('clubs')); }
  public function destroy($id){ Club::where('id',$id)->delete(); ClubMember::where('club_id',$id)->delete(); return back(); }
}
