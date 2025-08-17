<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ModerationItem;
use App\Models\CatchComment;

class ModerationController extends Controller
{
    public function index()
    {
        return ModerationItem::where('status','pending')->latest()->limit(100)->get();
    }

    public function approve($id)
    {
        $item = ModerationItem::findOrFail($id);
        $item->status = 'approved'; $item->save();
        if ($item->type === 'comment') {
            $c = CatchComment::find($item->ref_id);
            if ($c) { $c->status = 'approved'; $c->save(); }
        }
        return ['ok'=>true];
    }

    public function reject($id)
    {
        $item = ModerationItem::findOrFail($id);
        $item->status = 'rejected'; $item->save();
        if ($item->type === 'comment') {
            $c = CatchComment::find($item->ref_id);
            if ($c) { $c->status = 'rejected'; $c->save(); }
        }
        return ['ok'=>true];
    }
}
