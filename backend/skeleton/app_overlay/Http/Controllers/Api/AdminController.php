<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController; use App\Models\User; use App\Models\MapPoint; use App\Models\CatchRecord; use Illuminate\Http\Request;
class AdminController extends BaseController {
  public function stats(){ return ['users'=>User::count(),'map_points'=>MapPoint::count(),'catches'=>CatchRecord::count()]; }
  public function users(){ return User::select('id','name','email','is_admin','created_at')->orderBy('id','desc')->limit(100)->get(); }
  public function setFlags(Request $r){ // just echo, normally save to DB/kv
    return ['saved'=>$r->all()];
  }
}