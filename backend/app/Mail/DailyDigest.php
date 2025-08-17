<?php
namespace App\Mail; use Illuminate\Bus\Queueable; use Illuminate\Mail\Mailable; use Illuminate\Queue\SerializesModels;
class DailyDigest extends Mailable {
  use Queueable, SerializesModels;
  public function __construct(public array $data){}
  public function build(){ return $this->subject('FishTrackPro: дневной дайджест')->view('emails.digest'); }
}