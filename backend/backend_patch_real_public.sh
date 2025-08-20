#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[ -f artisan ] || { echo "artisan не найден (запустите из каталога backend)"; exit 1; }

mkdir -p app/Http/Controllers/Api app/Models

# --- Модели (если нет) ---
cat > app/Models/CatchRecord.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class CatchRecord extends Model {
  protected $fillable=['lat','lng','fish','weight','length','style','privacy','user_id','created_at','updated_at'];
  protected $casts=['created_at'=>'datetime','updated_at'=>'datetime'];
}
PHP

cat > app/Models/Event.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Event extends Model {
  protected $fillable=['title','description','starts_at','ends_at','region','creator_id'];
  protected $casts=['starts_at'=>'datetime','ends_at'=>'datetime'];
}
PHP

cat > app/Models/FishingPoint.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class FishingPoint extends Model {
  protected $fillable=['title','type','lat','lng','is_highlighted','is_approved'];
  protected $casts=['is_highlighted'=>'boolean','is_approved'=>'boolean'];
}
PHP

cat > app/Models/Club.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Club extends Model {
  protected $fillable=['name','logo','description','owner_id'];
}
PHP

# --- Контроллеры (реальные выборки) ---
cat > app/Http/Controllers/Api/HealthController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
class HealthController extends Controller {
  public function ping(){ return response()->json(['ok'=>true,'ts'=>now()->toISOString()]); }
}
PHP

cat > app/Http/Controllers/Api/MapController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\FishingPoint;
use Illuminate\Support\Facades\Schema;

class MapController extends Controller {
  public function index(Request $r){
    $q = FishingPoint::query();
    if (Schema::hasColumn('fishing_points','is_approved')) $q->where('is_approved',true);
    if ($r->filled('filter')) $q->where('type',$r->string('filter'));
    if ($r->filled('bbox')) { // bbox: "minLng,minLat,maxLng,maxLat"
      [$minLng,$minLat,$maxLng,$maxLat] = array_map('floatval', explode(',',$r->string('bbox')));
      $q->whereBetween('lat', [$minLat,$maxLat])->whereBetween('lng',[$minLng,$maxLng]);
    }
    return response()->json(['items'=>$q->orderByDesc('id')->limit(1000)->get()]);
  }
  public function store(Request $r){
    $data=$r->validate(['title'=>'required','type'=>'required','lat'=>'required|numeric','lng'=>'required|numeric']);
    $data['is_highlighted']=$r->boolean('is_highlighted',false);
    $data['is_approved']=true;
    return response()->json(FishingPoint::create($data),201);
  }
  public function show($id){ return response()->json(FishingPoint::findOrFail($id)); }
  public function update(Request $r,$id){ $p=FishingPoint::findOrFail($id); $p->fill($r->all())->save(); return response()->json($p); }
  public function destroy($id){ FishingPoint::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
  public function categories(){ return response()->json(['items'=>['shop','slip','camp','catch','spot']]); }
  public function list(){ return response()->json(['items'=>FishingPoint::orderByDesc('id')->paginate(20)]); }
}
PHP

cat > app/Http/Controllers/Api/CatchesController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CatchRecord;

class CatchesController extends Controller {
  public function index(Request $r){
    $q = CatchRecord::query();
    // публично показываем только privacy in ['all'] (без авторизации)
    $q->where('privacy','all');
    if ($r->filled('near')){
      [$lat,$lng] = array_map('floatval', explode(',',$r->string('near'))); // "lat,lng"
      $q->orderByRaw('(abs(lat-?)+abs(lng-?)) asc', [$lat,$lng]);
    } else {
      $q->orderByDesc('id');
    }
    return response()->json(['items'=>$q->limit(200)->get()]);
  }
  public function store(Request $r){
    $data = $r->validate([
      'lat'=>'required|numeric','lng'=>'required|numeric',
      'fish'=>'required|string','weight'=>'nullable|numeric','length'=>'nullable|numeric',
      'style'=>'in:shore,boat,ice','privacy'=>'in:all,friends,groups,none'
    ]);
    $data['style'] = $data['style'] ?? 'shore';
    $data['privacy'] = $data['privacy'] ?? 'all';
    return response()->json(CatchRecord::create($data),201);
  }
  public function show($id){ return response()->json(CatchRecord::findOrFail($id)); }
  public function update(Request $r,$id){ $c=CatchRecord::findOrFail($id); $c->fill($r->all())->save(); return response()->json($c); }
  public function destroy($id){ CatchRecord::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
}
PHP

cat > app/Http/Controllers/Api/EventsController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Event;

class EventsController extends Controller {
  public function index(Request $r){
    $q=Event::query();
    if ($r->filled('region')) $q->where('region',$r->string('region'));
    if ($r->boolean('upcoming',false)) $q->where('starts_at','>=',now());
    $q->orderBy('starts_at','asc');
    return response()->json(['items'=>$q->limit(300)->get()]);
  }
  public function store(Request $r){
    $data=$r->validate(['title'=>'required','description'=>'nullable','starts_at'=>'required|date','ends_at'=>'nullable|date','region'=>'nullable|string']);
    return response()->json(Event::create($data),201);
  }
  public function show($id){ return response()->json(Event::findOrFail($id)); }
  public function update(Request $r,$id){ $e=Event::findOrFail($id); $e->fill($r->all())->save(); return response()->json($e); }
  public function destroy($id){ Event::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
  public function byClub($clubId){ return response()->json(['items'=>Event::where('creator_id',$clubId)->orderBy('starts_at')->get()]); }
}
PHP

cat > app/Http/Controllers/Api/ClubsController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Club;

class ClubsController extends Controller {
  public function index(){ return response()->json(['items'=>Club::orderByDesc('id')->limit(300)->get()]); }
  public function store(Request $r){
    $data=$r->validate(['name'=>'required|min:2','logo'=>'nullable','description'=>'nullable']);
    return response()->json(Club::create($data),201);
  }
  public function show($id){ return response()->json(Club::findOrFail($id)); }
  public function update(Request $r,$id){ $c=Club::findOrFail($id); $c->fill($r->only('name','logo','description'))->save(); return response()->json($c); }
  public function destroy($id){ Club::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
}
PHP

cat > app/Http/Controllers/Api/FeedController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CatchRecord;

class FeedController extends Controller {
  public function global(){ return response()->json(['items'=>CatchRecord::where('privacy','all')->orderByDesc('id')->limit(200)->get()]); }
  public function local(Request $r){
    $lat=(float)$r->query('lat',55.76); $lng=(float)$r->query('lng',37.64);
    $items = CatchRecord::where('privacy','all')->orderByRaw('(abs(lat-?)+abs(lng-?)) asc',[$lat,$lng])->limit(100)->get();
    return response()->json(['items'=>$items]);
  }
  public function follow(){ return response()->json(['items'=>CatchRecord::where('privacy','all')->orderByDesc('id')->limit(50)->get()]); }
}
PHP

# --- Полные маршруты ---
cat > routes/api.php <<'PHP'
<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\{
  HealthController, MapController, CatchesController, EventsController, FeedController, ClubsController
};

Route::get('/health',[HealthController::class,'ping']);

Route::prefix('v1')->group(function(){
  // Map (публично)
  Route::get('/map/points',[MapController::class,'index']);
  Route::post('/map/points',[MapController::class,'store']);
  Route::get('/map/points/{id}',[MapController::class,'show']);
  Route::put('/map/points/{id}',[MapController::class,'update']);
  Route::delete('/map/points/{id}',[MapController::class,'destroy']);
  Route::get('/map/categories',[MapController::class,'categories']);
  Route::get('/map/list',[MapController::class,'list']);

  // Catches (публичная лента по privacy=all)
  Route::get('/catches',[CatchesController::class,'index']);
  Route::post('/catches',[CatchesController::class,'store']);
  Route::get('/catches/{id}',[CatchesController::class,'show']);
  Route::put('/catches/{id}',[CatchesController::class,'update']);
  Route::delete('/catches/{id}',[CatchesController::class,'destroy']);

  // Events & Clubs (публично)
  Route::get('/events',[EventsController::class,'index']);
  Route::post('/events',[EventsController::class,'store']);
  Route::get('/events/{id}',[EventsController::class,'show']);
  Route::put('/events/{id}',[EventsController::class,'update']);
  Route::delete('/events/{id}',[EventsController::class,'destroy']);
  Route::get('/clubs/{clubId}/events',[EventsController::class,'byClub']);

  Route::get('/clubs',[ClubsController::class,'index']);
  Route::post('/clubs',[ClubsController::class,'store']);
  Route::get('/clubs/{id}',[ClubsController::class,'show']);
  Route::put('/clubs/{id}',[ClubsController::class,'update']);
  Route::delete('/clubs/{id}',[ClubsController::class,'destroy']);

  // Feed (публично)
  Route::get('/feed/global',[FeedController::class,'global']);
  Route::get('/feed/local',[FeedController::class,'local']);
  Route::get('/feed/follow',[FeedController::class,'follow']);
});
PHP

php artisan optimize:clear
echo "==> Backend patch applied."
