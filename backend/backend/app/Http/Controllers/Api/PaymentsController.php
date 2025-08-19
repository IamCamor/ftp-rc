<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use App\Models\Plan;
use App\Models\Payment;

class PaymentsController extends Controller {
  public function createCheckout(Request $r){
    $d=$r->validate(['provider'=>'required|string|in:stripe,yookassa','plan_id'=>'required|string','mode'=>'nullable|string']);
    $plan=Plan::where('code',$d['plan_id'])->first(); if(!$plan) return response()->json(['error'=>'Plan not found'],404);
    // Заглушка: создаем платеж как "created" и возвращаем фейковый URL
    $p=Payment::create(['provider'=>$d['provider'],'status'=>'created','amount'=>$plan->price,'currency'=>$plan->currency,'external_id'=>uniqid('chk_'),'payload'=>['plan'=>$plan->code]]);
    return response()->json(['checkout_url'=>url('/payments/fake/'.$p->external_id)]);
  }
  public function stripeWebhook(Request $r){ Log::info('stripe webhook',$r->all()); return response()->json(['ok'=>true]); }
  public function yookassaWebhook(Request $r){ Log::info('yookassa webhook',$r->all()); return response()->json(['ok'=>true]); }
}
