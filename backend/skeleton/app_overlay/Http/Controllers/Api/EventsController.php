<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController;
class EventsController extends BaseController {
  public function index(){ return [['id'=>1,'title'=>'Open Fishing Fest']]; }
  public function store(){ return ['created'=>true]; }
  public function subscribe($id){ return ['subscribed'=>$id]; }
}