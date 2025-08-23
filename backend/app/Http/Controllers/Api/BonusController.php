<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BonusTransaction;
use App\Services\BonusService;
use Illuminate\Http\Request;

class BonusController extends Controller
{
    public function __construct(private readonly BonusService $bonusService) {}

    public function me(Request $request) {
        $user = $request->user();
        $balance = $this->bonusService->getBalance($user);
        return response()->json([
            'balance'=>(int)$balance->balance,
            'lifetime_earned'=>(int)$balance->lifetime_earned,
            'lifetime_spent'=>(int)$balance->lifetime_spent,
            'is_pro'=>(bool)$user->is_pro,
            'pro_until'=>$user->pro_until,
        ]);
    }

    public function history(Request $request) {
        $user=$request->user();
        $items=BonusTransaction::where('user_id',$user->id)->orderByDesc('id')->paginate(50);
        return response()->json($items);
    }

    public function redeemPro(Request $request) {
        $user=$request->user();
        $tx=$this->bonusService->redeemForPro($user);
        return response()->json([
            'status'=>'ok',
            'transaction_id'=>$tx->id,
            'new_balance'=>(int)$this->bonusService->getBalance($user)->balance,
            'is_pro'=>(bool)$user->is_pro,
            'pro_until'=>$user->pro_until,
        ]);
    }
}
