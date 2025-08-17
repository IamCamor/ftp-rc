<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class EventReminder extends Mailable
{
    use Queueable, SerializesModels;
    public array $data;
    public function __construct(array $data){ $this->data = $data; }
    public function build(){ return $this->subject('Напоминание о событии')->view('emails.event_reminder'); }
}
