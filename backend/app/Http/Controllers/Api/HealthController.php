<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
class HealthController extends Controller {
  public function ping(){ return response()->json(['ok'=>true,'ts'=>now()->toISOString()]); }
}
