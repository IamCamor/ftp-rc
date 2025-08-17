<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController; use App\Models\CatchRecord;
class FeedController extends BaseController {
  public function global(){ return CatchRecord::latest()->limit(50)->get(); }
  public function local(){ return CatchRecord::latest()->limit(50)->get(); }
  public function follow(){ return CatchRecord::latest()->limit(50)->get(); }
  public function like($id){ return ['id'=>$id,'liked'=>true]; }
  public function comment($id){ return ['id'=>$id,'commented'=>true]; }
}