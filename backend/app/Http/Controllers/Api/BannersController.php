<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\BannerSlot;
use App\Models\Banner;
use App\Models\BannerImpression;
class BannersController extends Controller { public function slots(){ return BannerSlot::orderBy('id')->get(); } public function listForSlot($code){ $slot=BannerSlot::where('code',$code)->firstOrFail(); return Banner::where(['slot_id'=>$slot->id,'is_active'=>true])->orderBy('priority')->get(); } public function impression(Request $r,$bannerId){ BannerImpression::create(['banner_id'=>$bannerId,'user_id'=>$r->user()?->id,'session'=>$r->header('X-Session',''),'ip'=>$r->ip()]); return ['ok'=>true]; } }
