<?php
namespace App\Http\Middleware; use Closure; use Illuminate\Http\Request; use Symfony\Component\HttpFoundation\Response;
class EnsureAdmin { public function handle(Request $request, Closure $next): Response { $u=$request->user(); if(!$u || !$u->is_admin) return response()->json(['message'=>'Admin only'],403); return $next($request); } }