<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminUsersController extends Controller
{
    public function index()
    {
        $users = DB::table('users')->select('id','name','email')->limit(200)->get();
        $roles = DB::table('user_roles')->get()->groupBy('user_id');
        $rows = [];
        foreach ($users as $u) {
            $r = $roles[$u->id] ?? collect();
            $rnames = DB::table('roles')->whereIn('id', $r->pluck('role_id'))->pluck('name')->implode(',');
            $rows[] = ['id'=>$u->id,'name'=>$u->name,'email'=>$u->email,'roles'=>$rnames];
        }
        return response()->json($rows);
    }
    public function setRole(Request $r, int $id)
    {
        $r->validate(['role'=>'required|string']);
        $rid = DB::table('roles')->where('name',$r->string('role'))->value('id');
        if (!$rid) return response()->json(['error'=>'role_not_found'], 404);
        DB::table('user_roles')->updateOrInsert(['user_id'=>$id, 'role_id'=>$rid], []);
        return response()->json(['ok'=>true]);
    }
}
