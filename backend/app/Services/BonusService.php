<?php

namespace App\Services;

use App\Models\BonusTransaction;
use App\Models\User;
use App\Models\UserBonusBalance;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class BonusService
{
    private array $config;
    public function __construct() {
        $this->config = config('bonus');
    }

    public function getBalance(User $user): UserBonusBalance {
        return UserBonusBalance::firstOrCreate(['user_id'=>$user->id]);
    }

    public function earn(User $user, string $actionCode, array $meta=[]): BonusTransaction {
        $action = $this->config['actions'][$actionCode] ?? null;
        if (!$action) throw ValidationException::withMessages(['action'=>'Unknown action']);
        $points = (int)($action['points']??0);
        if ($points<=0) throw ValidationException::withMessages(['points'=>'Invalid']);

        // todo: антифрод проверки, лимиты
        return DB::transaction(function() use ($user,$actionCode,$points,$meta){
            $balance = UserBonusBalance::lockForUpdate()->firstOrCreate(['user_id'=>$user->id]);
            $tx = BonusTransaction::create([
                'user_id'=>$user->id,
                'action_code'=>$actionCode,
                'amount'=>$points,
                'meta'=>empty($meta)?null:json_encode($meta,JSON_UNESCAPED_UNICODE),
            ]);
            $balance->balance += $points;
            $balance->lifetime_earned += $points;
            $balance->save();
            return $tx;
        });
    }

    public function redeemForPro(User $user, ?Carbon $proUntil=null): BonusTransaction {
        $cost = (int)($this->config['pro_cost']??1000);
        return DB::transaction(function() use ($user,$cost,$proUntil){
            $balance = UserBonusBalance::lockForUpdate()->firstOrCreate(['user_id'=>$user->id]);
            if ($balance->balance < $cost)
                throw ValidationException::withMessages(['balance'=>'Not enough points']);

            $tx = BonusTransaction::create([
                'user_id'=>$user->id,
                'action_code'=>'pro_purchase',
                'amount'=>-$cost,
                'meta'=>null,
            ]);
            $balance->balance -= $cost;
            $balance->lifetime_spent += $cost;
            $balance->save();

            $user->is_pro = true;
            $user->pro_until = $proUntil ?: $user->pro_until;
            $user->save();

            return $tx;
        });
    }
}
