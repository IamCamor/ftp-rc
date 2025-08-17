<?php

namespace App\Http\Controllers\Api\Webhooks;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use App\Mail\PaymentReceipt;

class YookassaWebhookController extends Controller
{
    public function handle(Request $r)
    {
        $event = $r->all();
        $obj = $event['object'] ?? [];
        if (($event['event'] ?? '') === 'payment.succeeded') {
            $pid = DB::table('payments')->insertGetId([
                'user_id'=>1,'provider'=>'yookassa','provider_ref'=>$obj['id'] ?? null,
                'amount'=> (int) ($obj['amount']['value'] ?? 0), 'currency'=>strtoupper($obj['amount']['currency'] ?? 'RUB'),
                'status'=>'paid','meta'=>json_encode($obj), 'created_at'=>now(),'updated_at'=>now()
            ]);
            Mail::to('admin@fishtrackpro.local')->send(new PaymentReceipt(['plan'=>'Pro','amount'=>$obj['amount']['value'] ?? 0,'currency'=>strtoupper($obj['amount']['currency'] ?? 'RUB'),'payment_id'=>$pid]));
        }
        return response()->json(['ok'=>true]);
    }
}
