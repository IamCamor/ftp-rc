<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController;
class HealthController extends BaseController { public function index(){ return response()->json(['status'=>'ok','time'=>now()->toIso8601String(),'version'=>'1.0.0']); } }