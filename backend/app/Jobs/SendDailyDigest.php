<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;
use App\Models\Notification;

class SendDailyDigest implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(public int $userId) {}

    public function handle(): void
    {
        $items = Notification::where('user_id', $this->userId)
            ->where('created_at', '>=', now()->subDay())
            ->orderByDesc('id')->limit(50)->get();

        $html = view('emails.daily-digest', ['items' => $items])->render();
        Mail::raw(strip_tags($html), function($m){
            $m->to(env('ADMIN_EMAIL','admin@fishtrackpro.local'));
            $m->subject('FishTrackPro — Дайджест за сутки');
        });
    }
}
