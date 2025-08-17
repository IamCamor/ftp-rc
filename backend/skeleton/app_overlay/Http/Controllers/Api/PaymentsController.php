<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController;
class PaymentsController extends BaseController {
  public function featurePoint(){ return ['paid'=>true]; }
  public function subscribe(){ return ['subscribed'=>true]; }
  public function webhook($provider){ return ['provider'=>$provider,'ok'=>true]; }
}