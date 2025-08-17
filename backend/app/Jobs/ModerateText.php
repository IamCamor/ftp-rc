<?php
namespace App\Jobs;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use App\Models\ModerationItem;
use App\Models\CatchComment;
class ModerateText implements ShouldQueue {
  use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;
  public function __construct(public int $refId, public string $type){}
  public function handle(): void {
    $item = ModerationItem::where('type',$this->type)->where('ref_id',$this->refId)->latest()->first();
    if (!$item) return;
    $item->status='approved'; $item->result=['ok'=>true,'provider'=>$item->provider]; $item->save();
    if ($this->type==='comment') { $c = CatchComment::find($this->refId); if ($c){ $c->status='approved'; $c->save(); } }
  }
}