<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
class HealthController extends Controller { public function index(){ return response()->json(['ok'=>true]); } }
