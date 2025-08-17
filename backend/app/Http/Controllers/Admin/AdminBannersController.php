<?php
namespace App\Http\Controllers\Admin;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\BannerSlot;
use App\Models\Banner;
class AdminBannersController extends Controller{
  public function index(){ $slots=BannerSlot::with('banners')->get(); return view('admin.banners.index', compact('slots')); }
  public function storeSlot(Request $r){ $data=$r->validate(['code'=>'required|string|max:64','title'=>'required|string|max:255']); BannerSlot::firstOrCreate(['code'=>$data['code']],['title'=>$data['title']]); return back(); }
  public function storeBanner(Request $r){ $data=$r->validate(['slot_id'=>'required|integer','title'=>'required|string','image'=>'nullable|url','link'=>'nullable|url']); Banner::create($data); return back(); }
  public function destroyBanner($id){ Banner::where('id',$id)->delete(); return back(); }
}
