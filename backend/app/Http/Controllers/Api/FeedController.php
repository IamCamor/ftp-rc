<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CatchRecord;

class FeedController extends Controller {
  public function global(){ return response()->json(['items'=>CatchRecord::where('privacy','all')->orderByDesc('id')->limit(200)->get()]); }
  public function local(Request $r){
    $lat=(float)$r->query('lat',55.76); $lng=(float)$r->query('lng',37.64);
    $items = CatchRecord::where('privacy','all')->orderByRaw('(abs(lat-?)+abs(lng-?)) asc',[$lat,$lng])->limit(100)->get();
    return response()->json(['items'=>$items]);
  }
  public function follow(){ return response()->json(['items'=>CatchRecord::where('privacy','all')->orderByDesc('id')->limit(50)->get()]); }
}
