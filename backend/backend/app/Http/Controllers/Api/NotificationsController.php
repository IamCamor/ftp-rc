<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Notification;
use App\Models\NotificationSetting;
class NotificationsController extends Controller {
  public function index(Request $r){ $type=$r->query('type'); $q=Notification::query()->orderByDesc('id')->limit(200); if($type) $q->where('type',$type); return response()->json($q->get()); }
  public function markRead($id){ $n=Notification::findOrFail($id); $n->is_read=true; $n->save(); return response()->json(['ok'=>true]); }
  public function readAll(){ Notification::query()->update(['is_read'=>true]); return response()->json(['ok'=>true]); }
  public function settings(Request $r){ $uid=(int)$r->query('user_id',0); $s=NotificationSetting::firstOrCreate(['user_id'=>$uid],[]); return response()->json($s); }
  public function saveSettings(Request $r){ $d=$r->validate(['user_id'=>'required|integer','push_enabled'=>'boolean','email_enabled'=>'boolean','likes_enabled'=>'boolean','comments_enabled'=>'boolean','system_enabled'=>'boolean']); $s=NotificationSetting::updateOrCreate(['user_id'=>$d['user_id']],$d); return response()->json($s); }
  public function createTest(){ return response()->json(Notification::create(['user_id'=>0,'type'=>'system','title'=>'Demo','body'=>'Demo notification','is_read'=>false])); }
}
