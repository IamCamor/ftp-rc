<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\BonusService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BonusTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_earn_and_redeem_pro(): void {
        $user = User::factory()->create();
        $svc = app(BonusService::class);

        for ($i=0; $i<20; $i++) {
            $svc->earn($user,'catch_add');
        }

        $balance = $svc->getBalance($user);
        $this->assertGreaterThanOrEqual(1000,$balance->balance);

        $svc->redeemForPro($user);

        $user->refresh();
        $this->assertTrue($user->is_pro);
    }
}
