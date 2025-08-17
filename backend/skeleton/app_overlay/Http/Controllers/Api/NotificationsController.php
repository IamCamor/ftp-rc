<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController;
class NotificationsController extends BaseController {
  public function index(){ return [['id'=>1,'type'=>'like','read'=>false],['id'=>2,'type'=>'comment','read'=>true]]; }
  public function read(){ return ['ok'=>true]; }
}