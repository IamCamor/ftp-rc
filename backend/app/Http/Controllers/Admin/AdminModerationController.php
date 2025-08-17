<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use App\Models\ModerationItem;
use App\Models\CatchComment;
class AdminModerationController extends Controller{
  public function index(){ $items=ModerationItem::where('status','pending')->orderBy('created_at','desc')->paginate(50); return view('admin.moderation.index', compact('items')); }
  public function approve($id){ $m=ModerationItem::findOrFail($id); $m->status='approved'; $m->save(); if($m->type==='comment'){ $c=CatchComment::find($m->ref_id); if($c){ $c->status='approved'; $c->save(); } } return back(); }
  public function reject($id){ $m=ModerationItem::findOrFail($id); $m->status='rejected'; $m->save(); if($m->type==='comment'){ $c=CatchComment::find($m->ref_id); if($c){ $c->status='rejected'; $c->save(); } } return back(); }
}
