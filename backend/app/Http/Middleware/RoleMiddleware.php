<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, string $role)
    {
        $userId = 1; // demo (replace with auth()->id())
        $has = DB::table('user_roles')->join('roles','roles.id','=','user_roles.role_id')
            ->where('user_roles.user_id',$userId)->where('roles.name',$role)->exists();
        if (!$has) { return response()->json(['error'=>'forbidden'], 403); }
        return $next($request);
    }
}
