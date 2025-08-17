<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class CommentApproved extends Mailable
{
    use Queueable, SerializesModels;
    public array $data;
    public function __construct(array $data){ $this->data = $data; }
    public function build(){ return $this->subject('Комментарий опубликован')->view('emails.comment_approved'); }
}
