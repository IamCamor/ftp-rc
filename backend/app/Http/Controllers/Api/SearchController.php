<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
class SearchController extends Controller { public function global(Request $r){ $q=trim($r->string('q')); if($q==='') return ['results'=>[]]; $limit=(int)$r->integer('limit',10); $res=[ 'map_points'=>DB::table('map_points')->select('id','title','lat','lng','type')->where('title','like',"%$q%")->limit($limit)->get(), 'catches'=>DB::table('catch_records')->select('id','species','lat','lng','weight','length')->where('species','like',"%$q%")->limit($limit)->get(), 'clubs'=>DB::table('clubs')->select('id','name')->where('name','like',"%$q%")->limit($limit)->get(), 'events'=>DB::table('events')->select('id','title','region','starts_at')->where('title','like',"%$q%")->limit($limit)->get(), 'users'=>DB::table('users')->select('id','name')->where('name','like',"%$q%")->limit($limit)->get(), ]; return ['query'=>$q,'results'=>$res]; } }
