<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use App\Models\MapPoint;
class AdminPointsController extends Controller{
  public function index(){ $points=MapPoint::orderBy('created_at','desc')->paginate(20); return view('admin.points.index', compact('points')); }
  public function feature($id){ $p=MapPoint::findOrFail($id); $p->is_featured=!$p->is_featured; $p->save(); return back(); }
  public function destroy($id){ $p=MapPoint::findOrFail($id); $p->delete(); return back(); }
}
