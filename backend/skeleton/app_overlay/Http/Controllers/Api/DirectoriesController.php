<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController;
class DirectoriesController extends BaseController {
  public function species(){ return [['id'=>1,'name'=>'Pike'],['id'=>2,'name'=>'Carp']]; }
  public function knots(){ return [['id'=>1,'name'=>'Uni Knot']]; }
  public function lures(){ return [['id'=>1,'name'=>'Spinner']]; }
  public function gears(){ return [['id'=>1,'name'=>'Spinning']]; }
  public function recipes(){ return [['id'=>1,'name'=>'Fried Perch']]; }
}