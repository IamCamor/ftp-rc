<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController;
class FlagsController extends BaseController { public function index(){ return response()->json(config('featureflags')); } }