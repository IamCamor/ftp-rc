<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Subscription;
use App\Models\Payment;
use Illuminate\Support\Str;
class BillingController extends Controller {
  public function createPayment(Request $r){
    $data=$r->validate(['purpose'=>'required|string|in:subscription,highlight_point,donation','provider'=>'required|string|in:stripe,yookassa,paypal,sber,yandex_pay','amount'=>'required|numeric|min:1','currency'=>'nullable|string|max:8','plan'=>'nullable|string']);
    $intent=Payment::create(['user_id'=>$r->user()?->id,'provider'=>$data['provider'],'intent_id'=>'pi_'.Str::random(18),'status'=>'pending','currency'=>$data['currency']??'RUB','amount'=>$data['amount'],'purpose'=>$data['purpose'],'metadata'=>['plan'=>$data['plan']??null],]);
    return response()->json(['payment_id'=>$intent->id,'checkout_url'=>url('/payments/checkout/'.$intent->id)],201);
  }
  public function webhook(Request $r,$provider){ $payload=$r->all(); $paymentId=$payload['payment_id']??null; if(!$paymentId) return response()->json(['ok'=>False,'error'=>'payment_id required'],422); $pay=Payment::findOrFail($paymentId); $status=$payload['status']??'succeeded'; $pay->status=$status; $pay->save(); if($pay->purpose==='subscription' && $status==='succeeded'){ Subscription::updateOrCreate(['user_id'=>$pay->user_id,'plan'=>$pay->metadata['plan']??'pro'], ['status'=>'active','period'=>'month','provider'=>$provider,'renews_at'=>now()->addMonth()]); } return ['ok'=>true]; }
  public function mySubscription(Request $r){ $sub=Subscription::where('user_id',$r->user()->id)->latest()->first(); return $sub?:response()->json(null,204); }
  public function cancel(Request $r){ $sub=Subscription::where('user_id',$r->user()->id)->latest()->firstOrFail(); $sub->status='canceled'; $sub->renews_at=null; $sub->save(); return ['ok'=>true]; }
}
