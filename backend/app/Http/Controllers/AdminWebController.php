<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminWebController extends Controller
{
    public function index() { return view('admin.index'); }
    public function comments() { $items = DB::table('catch_comments')->orderByDesc('id')->limit(200)->get(); return view('admin.comments', compact('items')); }
    public function approveComment(int $id){ DB::table('catch_comments')->where('id',$id)->update(['is_approved'=>true]); return back(); }
    public function rejectComment(int $id){ DB::table('catch_comments')->where('id',$id)->delete(); return back(); }
    public function points() { $items = DB::table('fishing_points')->orderByDesc('id')->limit(200)->get(); return view('admin.points', compact('items')); }
    public function approvePoint(int $id){ DB::table('fishing_points')->where('id',$id)->update(['status'=>'approved']); return back(); }
    public function rejectPoint(int $id){ DB::table('fishing_points')->where('id',$id)->delete(); return back(); }
    public function users() { $items = DB::table('users')->orderBy('id')->limit(200)->get(); $roles = DB::table('roles')->get(); return view('admin.users', compact('items','roles')); }
    public function setRole(Request $r, int $id){
        $rid = DB::table('roles')->where('name',$r->input('role'))->value('id');
        if ($rid) DB::table('user_roles')->updateOrInsert(['user_id'=>$id,'role_id'=>$rid], []);
        return back();
    }
}
