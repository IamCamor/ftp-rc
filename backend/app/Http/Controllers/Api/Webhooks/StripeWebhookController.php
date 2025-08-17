<?php

namespace App\Http\Controllers\Api\Webhooks;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use App\Mail\PaymentReceipt;
use Stripe\Webhook;

class StripeWebhookController extends Controller
{
    public function handle(Request $r)
    {
        $secret = env('STRIPE_WEBHOOK_SECRET');
        $payload = $r->getContent();
        $sig = $r->server('HTTP_STRIPE_SIGNATURE');
        try {
            if ($secret) { $event = Webhook::constructEvent($payload, $sig, $secret); }
            else { $event = json_decode($payload, true); }
        } catch (\Throwable $e) { return response()->json(['error'=>'invalid_signature'], 400); }

        $type = is_array($event) ? ($event['type'] ?? '') : $event->type;
        if ($type === 'checkout.session.completed') {
            $obj = is_array($event) ? ($event['data']['object'] ?? []) : $event->data->object;
            $pid = DB::table('payments')->insertGetId([
                'user_id'=>1,'provider'=>'stripe','provider_ref'=>$obj['id'] ?? null,
                'amount'=> (int) (($obj['amount_total'] ?? 0)/100), 'currency'=>strtoupper($obj['currency'] ?? 'RUB'),
                'status'=>'paid','meta'=>json_encode($obj), 'created_at'=>now(),'updated_at'=>now()
            ]);
            try { Mail::to('admin@fishtrackpro.local')->send(new PaymentReceipt(['plan'=>'Pro','amount'=>($obj['amount_total']??0)/100,'currency'=>strtoupper($obj['currency']??'RUB'),'payment_id'=>$pid])); } catch (\Throwable $e) { Log::warning('mail fail: '.$e->getMessage()); }
        }
        return response()->json(['ok'=>true]);
    }
}
