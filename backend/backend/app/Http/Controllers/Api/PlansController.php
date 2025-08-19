<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Plan;
class PlansController extends Controller {
  public function index(){
    $plans=Plan::orderBy('price')->get()->map(fn($p)=>['id'=>$p->code,'title'=>$p->title,'price'=>$p->price,'currency'=>$p->currency,'interval'=>$p->interval,'features'=>$p->features?:['Карты','Фильтры','Pro-бейдж']]);
    return response()->json($plans);
  }
}
