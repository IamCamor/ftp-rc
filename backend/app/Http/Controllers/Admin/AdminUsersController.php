<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
class AdminUsersController extends Controller{
  public function index(){ $users=User::orderBy('created_at','desc')->paginate(20); return view('admin.users.index', compact('users')); }
  public function toggleAdmin($id){ $u=User::findOrFail($id); $u->is_admin=!$u->is_admin; $u->save(); return back()->with('ok','updated'); }
}
