<?php
namespace App\Http\Controllers\Api; use Illuminate\Routing\Controller as BaseController;
class SearchController extends BaseController { public function search(){ return ['results'=>[]]; } }