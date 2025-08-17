<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Notification;

class NotificationsController extends Controller {
  public function index(Request $r){
    $uid = auth()->id();
    $q = Notification::where('user_id',$uid)->latest();
    if ($r->filled('type')) $q->where('type',$r->string('type'));
    if ($r->filled('read')) $q->where('is_read', $r->boolean('read'));
    return $q->paginate(30);
  }
  public function markRead($id){
    $uid = auth()->id();
    $n = Notification::where('user_id',$uid)->findOrFail($id);
    $n->is_read = true; $n->save();
    return ['ok'=>true];
  }
}