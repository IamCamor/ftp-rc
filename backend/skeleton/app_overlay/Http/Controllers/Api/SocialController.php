<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController;
class SocialController extends BaseController {
  public function request($userId){ return ['requested'=>$userId]; }
  public function accept($userId){ return ['accepted'=>$userId]; }
  public function list(){ return [['id'=>1,'name'=>'Friend One']]; }
}