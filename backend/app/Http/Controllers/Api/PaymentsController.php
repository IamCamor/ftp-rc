<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class PaymentsController extends Controller
{
    public function plans()
    {
        return response()->json([
            ['id'=>'pro_month', 'title'=>'Pro Месяц', 'price'=>499, 'currency'=>'RUB', 'interval'=>'month'],
            ['id'=>'pro_year', 'title'=>'Pro Год', 'price'=>3990, 'currency'=>'RUB', 'interval'=>'year'],
        ]);
    }

    public function createCheckout(Request $r)
    {
        $r->validate([ 'provider'=>'required|in:stripe,yookassa', 'plan_id'=>'required|string', 'mode'=>'required|in:subscription,one_time' ]);
        $amount = 0; $desc = 'FishTrackPro Pro'; $currency='RUB';
        if ($r->string('plan_id')==='pro_month'){ $amount=499; $desc.=' (месяц)'; }
        if ($r->string('plan_id')==='pro_year'){ $amount=3990; $desc.=' (год)'; }
        $success = config('app.url').'/payments/success';
        $cancel = config('app.url').'/payments/cancel';

        if ($r->string('provider')==='stripe') {
            $sk = env('STRIPE_SECRET'); 
            // if (!$sk) { return response()->json({'error'=>'STRIPE_SECRET missing'},500)}
            $res = Http::withToken($sk)->asForm()->post('https://api.stripe.com/v1/checkout/sessions', [
                'mode' => $r->string('mode')==='subscription' ? 'subscription' : 'payment',
                'success_url' => $success, 'cancel_url' => $cancel,
                'line_items[0][price_data][currency]' => strtolower($currency),
                'line_items[0][price_data][product_data][name]' => $desc,
                'line_items[0][price_data][recurring][interval]' => $r->string('mode')==='subscription' ? 'month' : null,
                'line_items[0][price_data][unit_amount]' => intval($amount * 100),
                'line_items[0][quantity]' => 1,
            ]);
            if (!$res->ok()) return response()->json(['error'=>'stripe_error','detail'=>$res->json()], 500);
            return response()->json(['checkout_url' => $res->json()['url'] ?? null]);
        }

        $shopId = env('YOOKASSA_SHOP_ID'); $secret = env('YOOKASSA_SECRET');
        if (!$shopId || !$secret) return response()->json(['error'=>'YOOKASSA credentials missing'], 500);
        $res = Http::withHeaders(['Idempotence-Key'=>(string) Str::uuid()])->withBasicAuth($shopId,$secret)->post('https://api.yookassa.ru/v3/payments', [
            'amount' => ['value'=>number_format($amount,2,'.',''),'currency'=>$currency],
            'capture' => true,
            'confirmation' => ['type'=>'redirect','return_url'=>$success],
            'description' => $desc
        ]);
        if (!$res->ok()) return response()->json(['error'=>'yookassa_error','detail'=>$res->json()], 500);
        return response()->json(['checkout_url'=>$res->json()['confirmation']['confirmation_url'] ?? null]);
    }

    public function subscriptionStatus(){ return response()->json(['status'=>'active']); }
    public function highlightPoint(Request $r){ $r->validate(['point_id'=>'required|integer']); return response()->json(['ok'=>true]); }
    public function cancelSubscription(){ return response()->json(['ok'=>true]); }
}
