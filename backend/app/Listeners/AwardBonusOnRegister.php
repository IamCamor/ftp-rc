<?php

namespace App\Listeners;

use App\Services\BonusService;
use Illuminate\Auth\Events\Registered;

class AwardBonusOnRegister
{
    public function __construct(private readonly BonusService $bonusService) {}

    public function handle(Registered $event): void
    {
      $user = $event->user;
      try {
          $this->bonusService->earn($user, 'register');
      } catch (\Throwable $e) {
          logger()->warning('Bonus earn failed on register', [
              'user_id' => $user->id ?? null,
              'error' => $e->getMessage(),
          ]);
      }
    }
}
