<?php
namespace App\Http\Controllers\Api; use Illuminate\Http\Request; use Illuminate\Routing\Controller as BaseController; use App\Models\CatchRecord;
class CatchesController extends BaseController {
  public function list(){ return CatchRecord::latest()->limit(100)->get(); }
  public function store(Request $r){ $d=$r->validate(['lat'=>'required|numeric','lng'=>'required|numeric','species'=>'nullable','length'=>'nullable|numeric','weight'=>'nullable|numeric']); $d['user_id']=$r->user()->id; return CatchRecord::create($d); }
}