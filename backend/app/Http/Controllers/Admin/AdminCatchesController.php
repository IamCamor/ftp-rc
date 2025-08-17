<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use App\Models\CatchRecord;
class AdminCatchesController extends Controller{
  public function index(){ $catches=CatchRecord::orderBy('created_at','desc')->paginate(20); return view('admin.catches.index', compact('catches')); }
  public function destroy($id){ $c=CatchRecord::findOrFail($id); $c->delete(); return back(); }
}
