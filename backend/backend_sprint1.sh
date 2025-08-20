#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
[ -f artisan ] || { echo "Запусти из каталога backend (где artisan)"; exit 1; }

echo "==> S1: модели, миграции, контроллеры, загрузка фото"

# 1) Модели
mkdir -p app/Models app/Http/Controllers/Api database/migrations

cat > app/Models/Media.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class Media extends Model {
  protected $fillable=['disk','path','url','type','size','meta'];
  protected $casts=['meta'=>'array'];
}
PHP

cat > app/Models/CatchRecord.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class CatchRecord extends Model {
  protected $fillable=['lat','lng','fish','weight','length','style','privacy','photo_id','created_at','updated_at'];
  protected $casts=['created_at'=>'datetime','updated_at'=>'datetime'];
  public function photo(){ return $this->belongsTo(\App\Models\Media::class,'photo_id'); }
}
PHP

cat > app/Models/FishingPoint.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class FishingPoint extends Model {
  protected $fillable=['title','type','lat','lng','is_highlighted','is_approved','photo_id'];
  protected $casts=['is_highlighted'=>'boolean','is_approved'=>'boolean'];
  public function photo(){ return $this->belongsTo(\App\Models\Media::class,'photo_id'); }
}
PHP

# 2) Миграции (безопасно добавляем недостающие поля)
cat > database/migrations/2025_08_20_120000_create_media_and_extend_tables.php <<'PHP'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
  public function up(): void {
    if (!Schema::hasTable('media')) {
      Schema::create('media', function(Blueprint $t){
        $t->id();
        $t->string('disk')->default('public');
        $t->string('path');
        $t->string('url');
        $t->string('type')->nullable();
        $t->unsignedBigInteger('size')->nullable();
        $t->json('meta')->nullable();
        $t->timestamps();
      });
    }
    if (Schema::hasTable('fishing_points') && !Schema::hasColumn('fishing_points','photo_id')) {
      Schema::table('fishing_points', fn(Blueprint $t)=>$t->unsignedBigInteger('photo_id')->nullable()->after('is_approved'));
    }
    if (Schema::hasTable('catch_records') && !Schema::hasColumn('catch_records','photo_id')) {
      Schema::table('catch_records', fn(Blueprint $t)=>$t->unsignedBigInteger('photo_id')->nullable()->after('privacy'));
    }
  }
  public function down(): void {
    if (Schema::hasTable('fishing_points') && Schema::hasColumn('fishing_points','photo_id')) {
      Schema::table('fishing_points', fn(Blueprint $t)=>$t->dropColumn('photo_id'));
    }
    if (Schema::hasTable('catch_records') && Schema::hasColumn('catch_records','photo_id')) {
      Schema::table('catch_records', fn(Blueprint $t)=>$t->dropColumn('photo_id'));
    }
    if (Schema::hasTable('media')) Schema::drop('media');
  }
};
PHP

# 3) Контроллер для загрузки файлов
cat > app/Http/Controllers/Api/UploadController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Media;

class UploadController extends Controller {
  public function image(Request $r){
    $r->validate(['file'=>'required|file|mimes:jpg,jpeg,png,webp|max:8192']);
    $file = $r->file('file');
    $path = $file->store('uploads', 'public'); // storage/app/public/uploads/...
    $url  = Storage::disk('public')->url($path);
    $m = Media::create([
      'disk'=>'public','path'=>$path,'url'=>$url,
      'type'=>$file->getClientMimeType(),'size'=>$file->getSize(),'meta'=>['original'=>$file->getClientOriginalName()],
    ]);
    return response()->json($m,201);
  }
}
PHP

# 4) Контроллеры: точки/уловы (создание с привязкой фото)
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
    if ($r->filled('bbox')) {
      [$minLng,$minLat,$maxLng,$maxLat] = array_map('floatval', explode(',',$r->string('bbox')));
      $q->whereBetween('lat', [$minLat,$maxLat])->whereBetween('lng',[$minLng,$maxLng]);
    }
    $q->with('photo');
    return response()->json(['items'=>$q->orderByDesc('id')->limit(1000)->get()]);
  }
  public function store(Request $r){
    $data=$r->validate([
      'title'=>'required|string|min:2',
      'type'=>'required|in:shop,slip,camp,catch,spot',
      'lat'=>'required|numeric','lng'=>'required|numeric',
      'photo_id'=>'nullable|integer'
    ]);
    $data['is_highlighted']=$r->boolean('is_highlighted',false);
    $data['is_approved']=true;
    $p = FishingPoint::create($data);
    return response()->json($p->load('photo'),201);
  }
  public function show($id){ return response()->json(FishingPoint::with('photo')->findOrFail($id)); }
  public function update(Request $r,$id){ $p=FishingPoint::findOrFail($id); $p->fill($r->only(['title','type','lat','lng','is_highlighted','photo_id']))->save(); return response()->json($p->load('photo')); }
  public function destroy($id){ FishingPoint::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
  public function categories(){ return response()->json(['items'=>['shop','slip','camp','catch','spot']]); }
  public function list(){ return response()->json(['items'=>FishingPoint::with('photo')->orderByDesc('id')->paginate(20)]); }
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
    $q = CatchRecord::query()->where('privacy','all')->with('photo');
    if ($r->filled('near')){
      [$lat,$lng] = array_map('floatval', explode(',',$r->string('near')));
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
      'style'=>'nullable|in:shore,boat,ice','privacy'=>'nullable|in:all,friends,groups,none',
      'photo_id'=>'nullable|integer'
    ]);
    $data['style'] = $data['style'] ?? 'shore';
    $data['privacy'] = $data['privacy'] ?? 'all';
    $c = CatchRecord::create($data);
    return response()->json($c->load('photo'),201);
  }
  public function show($id){ return response()->json(CatchRecord::with('photo')->findOrFail($id)); }
  public function update(Request $r,$id){ $c=CatchRecord::findOrFail($id); $c->fill($r->only(['lat','lng','fish','weight','length','style','privacy','photo_id']))->save(); return response()->json($c->load('photo')); }
  public function destroy($id){ CatchRecord::whereKey($id)->delete(); return response()->json(['ok'=>true]); }
}
PHP

# 5) HealthController (на случай отсутствия)
cat > app/Http/Controllers/Api/HealthController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
class HealthController extends Controller {
  public function ping(){ return response()->json(['ok'=>true,'ts'=>now()->toISOString()]); }
}
PHP

# 6) Роуты
cat > routes/api.php <<'PHP'
<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\{HealthController,UploadController,MapController,CatchesController};

Route::get('/health',[HealthController::class,'ping']);

Route::prefix('v1')->group(function(){
  // загрузка фото
  Route::post('/upload/image',[UploadController::class,'image']);

  // карта/точки
  Route::get('/map/points',[MapController::class,'index']);
  Route::post('/map/points',[MapController::class,'store']);
  Route::get('/map/points/{id}',[MapController::class,'show']);
  Route::put('/map/points/{id}',[MapController::class,'update']);
  Route::delete('/map/points/{id}',[MapController::class,'destroy']);
  Route::get('/map/categories',[MapController::class,'categories']);
  Route::get('/map/list',[MapController::class,'list']);

  // уловы
  Route::get('/catches',[CatchesController::class,'index']);
  Route::post('/catches',[CatchesController::class,'store']);
  Route::get('/catches/{id}',[CatchesController::class,'show']);
  Route::put('/catches/{id}',[CatchesController::class,'update']);
  Route::delete('/catches/{id}',[CatchesController::class,'destroy']);
});
PHP

# 7) Симлинк и права
php artisan optimize:clear
#php artisan migrate --force || true
php artisan storage:link || true

chmod -R ug+rw storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache || true

echo "==> Готово. Проверь API: /api/health, /api/v1/upload/image, /api/v1/map/points, /api/v1/catches"
