<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController;
class RatingsController extends BaseController {
  public function top(){ return [['user_id'=>1,'score'=>123]]; }
  public function diversity(){ return [['user_id'=>1,'species_count'=>7]]; }
  public function records(){ return [['species'=>'Pike','weight'=>12.3]]; }
}