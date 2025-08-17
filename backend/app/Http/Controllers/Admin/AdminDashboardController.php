<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;
class AdminDashboardController extends Controller{
  public function index(){
    $stats=[
      'users'=>DB::table('users')->count(),
      'points'=>DB::schemaHasTable('map_points')?DB::table('map_points')->count():0,
      'catches'=>DB::schemaHasTable('catch_records')?DB::table('catch_records')->count():0,
      'events'=>DB::schemaHasTable('events')?DB::table('events')->count():0,
      'clubs'=>DB::schemaHasTable('clubs')?DB::table('clubs')->count():0,
    ];
    return view('admin.dashboard', compact('stats'));
  }
}
