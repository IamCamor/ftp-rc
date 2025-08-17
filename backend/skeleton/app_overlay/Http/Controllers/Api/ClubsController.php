<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController;
class ClubsController extends BaseController {
  public function index(){ return [['id'=>1,'name'=>'Carp Masters']]; }
  public function store(){ return ['created'=>true]; }
  public function join($clubId){ return ['joined'=>$clubId]; }
  public function events($clubId){ return [['club_id'=>$clubId,'id'=>1,'title'=>'Summer Cup']]; }
}