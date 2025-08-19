#!/usr/bin/env bash
set -euo pipefail

# === Настройки (поменяй при необходимости) ===
APP_DIR="${APP_DIR:-$PWD/backend}"
APP_URL="${APP_URL:-https://api.fishtrackpro.ru}"
FRONT_URL="${FRONT_URL:-https://fishtrackpro.ru}"

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_DATABASE="${DB_DATABASE:-fishtrackpro}"
DB_USERNAME="${DB_USERNAME:-ftp_user}"
DB_PASSWORD="${DB_PASSWORD:-ftp_pass}"

ADMIN_EMAIL="${ADMIN_EMAIL:-admin@fishtrackpro.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"

# === Проверка окружения ===
command -v php >/dev/null || { echo "❌ PHP не найден"; exit 1; }
command -v composer >/dev/null || { echo "❌ Composer не найден"; exit 1; }

echo "➡️  Целевая папка: $APP_DIR"
mkdir -p "$APP_DIR"

# === Установка Laravel, если нет ===
if [ ! -f "$APP_DIR/artisan" ]; then
  echo "📦 Устанавливаю Laravel в $APP_DIR ..."
  composer create-project laravel/laravel "$APP_DIR"
else
  echo "✅ Laravel уже установлен"
fi

cd "$APP_DIR"

# === Зависимости (HTTP клиент для погоды уже в Laravel) ===
composer install

# === .env ===
cat > .env <<EOF
APP_NAME=FishTrackPro
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=${APP_URL}

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}

FRONTEND_URL=${FRONT_URL}

OPENWEATHER_API_KEY=

MAIL_MAILER=log
MAIL_FROM_ADDRESS=no-reply@fishtrackpro.ru
MAIL_FROM_NAME="FishTrackPro"

ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

STRIPE_SECRET=
STRIPE_PUBLIC=
STRIPE_WEBHOOK_SECRET=
YOOKASSA_SHOP_ID=
YOOKASSA_SECRET_KEY=
YOOKASSA_WEBHOOK_SECRET=
EOF

php artisan key:generate

# === Конфиги ===
mkdir -p config
cat > config/cors.php <<'PHP'
<?php
return [
  'paths' => ['api/*','sanctum/csrf-cookie'],
  'allowed_methods' => ['*'],
  'allowed_origins' => [env('FRONTEND_URL','http://127.0.0.1:5173')],
  'allowed_origins_patterns' => [],
  'allowed_headers' => ['*'],
  'exposed_headers' => [],
  'max_age' => 0,
  'supports_credentials' => false,
];
PHP

cat > config/services.php <<'PHP'
<?php
return [
  'stripe' => [
    'key' => env('STRIPE_PUBLIC'),
    'secret' => env('STRIPE_SECRET'),
    'webhook_secret' => env('STRIPE_WEBHOOK_SECRET'),
  ],
  'yookassa' => [
    'shop_id' => env('YOOKASSA_SHOP_ID'),
    'secret' => env('YOOKASSA_SECRET_KEY'),
    'webhook_secret' => env('YOOKASSA_WEBHOOK_SECRET'),
  ],
];
PHP

# === Роуты ===
mkdir -p routes
cat > routes/api.php <<'PHP'
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\MapController;
use App\Http\Controllers\Api\CatchesController;
use App\Http\Controllers\Api\EventsController;
use App\Http\Controllers\Api\ClubsController;
use App\Http\Controllers\Api\PlansController;
use App\Http\Controllers\Api\PaymentsController;
use App\Http\Controllers\Api\WeatherController;
use App\Http\Controllers\Api\NotificationsController;

Route::get('/health', [HealthController::class,'index']);

Route::get('/map/points', [MapController::class,'index']);
Route::post('/map/points', [MapController::class,'store']);
Route::post('/map/points/{id}/photo', [MapController::class,'uploadPhoto']);

Route::post('/catches', [CatchesController::class,'store']);
Route::post('/catches/{id}/media', [CatchesController::class,'uploadMedia']);

Route::post('/events', [EventsController::class,'store']);
Route::post('/events/{id}/photo', [EventsController::class,'uploadPhoto']);

Route::post('/clubs', [ClubsController::class,'store']);
Route::post('/clubs/{id}/logo', [ClubsController::class,'uploadLogo']);

Route::get('/plans', [PlansController::class,'index']);
Route::post('/create-checkout', [PaymentsController::class,'createCheckout']);

Route::get('/weather', [WeatherController::class,'currentPlusDaily']);

Route::post('/webhooks/stripe', [PaymentsController::class,'stripeWebhook']);
Route::post('/webhooks/yookassa', [PaymentsController::class,'yookassaWebhook']);

Route::get('/notifications', [NotificationsController::class,'index']);
Route::post('/notifications/{id}/read', [NotificationsController::class,'markRead']);
Route::post('/notifications/read-all', [NotificationsController::class,'readAll']);
Route::get('/notifications/settings', [NotificationsController::class,'settings']);
Route::post('/notifications/settings', [NotificationsController::class,'saveSettings']);
Route::post('/notifications/create-test', [NotificationsController::class,'createTest']);
PHP

# === Контроллеры ===
mkdir -p app/Http/Controllers/Api
cat > app/Http/Controllers/Api/HealthController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
class HealthController extends Controller { public function index(){ return response()->json(['ok'=>true]); } }
PHP

cat > app/Http/Controllers/Api/MapController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\FishingPoint;
class MapController extends Controller {
  public function index(Request $r){
    $q=FishingPoint::query()->where('is_approved',true);
    if($r->filled('category') && $r->category!=='all'){ $q->where('category',$r->category); }
    return response()->json($q->orderByDesc('id')->limit(500)->get());
  }
  public function store(Request $r){
    $d=$r->validate(['title'=>'required|string|max:255','description'=>'nullable|string','category'=>'required|string|in:spot,shop,slip,resort','lat'=>'required|numeric','lng'=>'required|numeric','is_public'=>'boolean']);
    $d['is_highlighted']=false; $d['is_approved']=false; $p=FishingPoint::create($d); return response()->json($p);
  }
  public function uploadPhoto($id, Request $r){
    $r->validate(['file'=>'required|image|max:5120']); $p=FishingPoint::findOrFail($id);
    $path=$r->file('file')->store('points','public'); $p->photo_url=asset('storage/'.$path); $p->save();
    return response()->json(['ok'=>true,'photo_url'=>$p->photo_url]);
  }
}
PHP

cat > app/Http/Controllers/Api/CatchesController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\CatchRecord;
use App\Models\CatchMedia;
class CatchesController extends Controller {
  public function store(Request $r){
    $d=$r->validate(['lat'=>'nullable|numeric','lng'=>'nullable|numeric','species'=>'nullable|string|max:255','length'=>'nullable|numeric','weight'=>'nullable|numeric','depth'=>'nullable|numeric','style'=>'nullable|string|max:50','lure'=>'nullable|string|max:255','tackle'=>'nullable|string|max:255','privacy'=>'nullable|string|max:20','companions'=>'nullable|string|max:255','notes'=>'nullable|string','caught_at'=>'nullable|date']);
    $d['is_approved']=false; return response()->json(CatchRecord::create($d));
  }
  public function uploadMedia($id, Request $r){
    $r->validate(['file'=>'required|image|max:8192']); $rec=CatchRecord::findOrFail($id);
    $path=$r->file('file')->store('catches','public'); $url=asset('storage/'.$path);
    CatchMedia::create(['catch_id'=>$rec->id,'url'=>$url,'type'=>'image']); return response()->json(['ok'=>true,'url'=>$url]);
  }
}
PHP

cat > app/Http/Controllers/Api/EventsController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Event;
class EventsController extends Controller {
  public function store(Request $r){
    $d=$r->validate(['title'=>'required|string|max:255','region'=>'nullable|string|max:255','starts_at'=>'nullable|date','ends_at'=>'nullable|date','description'=>'nullable|string','location_lat'=>'nullable|numeric','location_lng'=>'nullable|numeric','link'=>'nullable|string|max:255']);
    $d['is_approved']=false; return response()->json(Event::create($d));
  }
  public function uploadPhoto($id, Request $r){
    $r->validate(['file'=>'required|image|max:8192']); $e=Event::findOrFail($id);
    $path=$r->file('file')->store('events','public'); $e->photo_url=asset('storage/'.$path); $e->save();
    return response()->json(['ok'=>true,'photo_url'=>$e->photo_url]);
  }
}
PHP

cat > app/Http/Controllers/Api/ClubsController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Club;
class ClubsController extends Controller {
  public function store(Request $r){
    $d=$r->validate(['name'=>'required|string|max:255','region'=>'nullable|string|max:255','description'=>'nullable|string']);
    $d['is_approved']=false; return response()->json(Club::create($d));
  }
  public function uploadLogo($id, Request $r){
    $r->validate(['file'=>'required|image|max:4096']); $c=Club::findOrFail($id);
    $path=$r->file('file')->store('clubs','public'); $c->logo_url=asset('storage/'.$path); $c->save();
    return response()->json(['ok'=>true,'logo_url'=>$c->logo_url]);
  }
}
PHP

cat > app/Http/Controllers/Api/PlansController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Plan;
class PlansController extends Controller {
  public function index(){
    $plans=Plan::orderBy('price')->get()->map(fn($p)=>['id'=>$p->code,'title'=>$p->title,'price'=>$p->price,'currency'=>$p->currency,'interval'=>$p->interval,'features'=>$p->features?:['Карты','Фильтры','Pro-бейдж']]);
    return response()->json($plans);
  }
}
PHP

cat > app/Http/Controllers/Api/PaymentsController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use App\Models\Plan;
use App\Models\Payment;

class PaymentsController extends Controller {
  public function createCheckout(Request $r){
    $d=$r->validate(['provider'=>'required|string|in:stripe,yookassa','plan_id'=>'required|string','mode'=>'nullable|string']);
    $plan=Plan::where('code',$d['plan_id'])->first(); if(!$plan) return response()->json(['error'=>'Plan not found'],404);
    // Заглушка: создаем платеж как "created" и возвращаем фейковый URL
    $p=Payment::create(['provider'=>$d['provider'],'status'=>'created','amount'=>$plan->price,'currency'=>$plan->currency,'external_id'=>uniqid('chk_'),'payload'=>['plan'=>$plan->code]]);
    return response()->json(['checkout_url'=>url('/payments/fake/'.$p->external_id)]);
  }
  public function stripeWebhook(Request $r){ Log::info('stripe webhook',$r->all()); return response()->json(['ok'=>true]); }
  public function yookassaWebhook(Request $r){ Log::info('yookassa webhook',$r->all()); return response()->json(['ok'=>true]); }
}
PHP

cat > app/Http/Controllers/Api/WeatherController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\WeatherCache;
use Carbon\Carbon;
class WeatherController extends Controller {
  public function currentPlusDaily(Request $r){
    $lat=$r->query('lat'); $lng=$r->query('lng'); $units=$r->query('units','metric'); $lang=$r->query('lang','en');
    if(!$lat||!$lng) return response()->json(['error'=>'lat/lng required'],422);
    $key=sprintf('lat:%s;lng:%s;u:%s;l:%s',$lat,$lng,$units,$lang);
    $cached=WeatherCache::where('key',$key)->first();
    if($cached && Carbon::parse($cached->fetched_at)->gt(now()->subMinutes(30))){
      return response()->json(['current'=>json_decode($cached->current,true),'daily'=>json_decode($cached->daily,true),'cached'=>true]);
    }
    $api=env('OPENWEATHER_API_KEY');
    if(!$api) return response()->json(['current'=>['temp'=>17.2,'wind_speed'=>4.1],'daily'=>[['dt'=>now()->timestamp,'temp'=>['min'=>12,'max'=>20]]],'cached'=>false]);
    $resp=Http::get('https://api.openweathermap.org/data/3.0/onecall',['lat'=>$lat,'lon'=>$lng,'units'=>$units,'lang'=>$lang,'exclude'=>'minutely,hourly,alerts','appid'=>$api]);
    if(!$resp->ok()) return response()->json(['error'=>'weather fetch failed'],500);
    $json=$resp->json();
    WeatherCache::updateOrCreate(['key'=>$key],['current'=>json_encode($json['current']??[]),'daily'=>json_encode($json['daily']??[]),'fetched_at'=>now()]);
    return response()->json(['current'=>$json['current']??[],'daily'=>$json['daily']??[],'cached'=>false]);
  }
}
PHP

cat > app/Http/Controllers/Api/NotificationsController.php <<'PHP'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Notification;
use App\Models\NotificationSetting;
class NotificationsController extends Controller {
  public function index(Request $r){ $type=$r->query('type'); $q=Notification::query()->orderByDesc('id')->limit(200); if($type) $q->where('type',$type); return response()->json($q->get()); }
  public function markRead($id){ $n=Notification::findOrFail($id); $n->is_read=true; $n->save(); return response()->json(['ok'=>true]); }
  public function readAll(){ Notification::query()->update(['is_read'=>true]); return response()->json(['ok'=>true]); }
  public function settings(Request $r){ $uid=(int)$r->query('user_id',0); $s=NotificationSetting::firstOrCreate(['user_id'=>$uid],[]); return response()->json($s); }
  public function saveSettings(Request $r){ $d=$r->validate(['user_id'=>'required|integer','push_enabled'=>'boolean','email_enabled'=>'boolean','likes_enabled'=>'boolean','comments_enabled'=>'boolean','system_enabled'=>'boolean']); $s=NotificationSetting::updateOrCreate(['user_id'=>$d['user_id']],$d); return response()->json($s); }
  public function createTest(){ return response()->json(Notification::create(['user_id'=>0,'type'=>'system','title'=>'Demo','body'=>'Demo notification','is_read'=>false])); }
}
PHP

# === Модели ===
mkdir -p app/Models
cat > app/Models/FishingPoint.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class FishingPoint extends Model{ protected $fillable=['title','description','category','lat','lng','is_public','is_highlighted','photo_url','is_approved']; }
PHP
cat > app/Models/CatchRecord.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class CatchRecord extends Model{ protected $table='catches'; protected $fillable=['lat','lng','species','length','weight','depth','style','lure','tackle','privacy','companions','notes','caught_at','is_approved']; protected $casts=['caught_at'=>'datetime']; }
PHP
cat > app/Models/CatchMedia.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class CatchMedia extends Model{ protected $fillable=['catch_id','url','type']; }
PHP
cat > app/Models/Event.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Event extends Model{ protected $fillable=['title','region','starts_at','ends_at','description','location_lat','location_lng','link','photo_url','is_approved']; protected $casts=['starts_at'=>'datetime','ends_at'=>'datetime']; }
PHP
cat > app/Models/Club.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Club extends Model{ protected $fillable=['name','region','description','logo_url','is_approved']; }
PHP
cat > app/Models/Plan.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Plan extends Model{ protected $fillable=['code','title','price','currency','interval','features']; protected $casts=['features'=>'array']; }
PHP
cat > app/Models/Payment.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Payment extends Model{ protected $fillable=['user_id','provider','status','amount','currency','external_id','payload']; protected $casts=['payload'=>'array']; }
PHP
cat > app/Models/WeatherCache.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class WeatherCache extends Model{ protected $table='weather_cache'; protected $fillable=['key','current','daily','fetched_at']; protected $casts=['fetched_at'=>'datetime']; }
PHP
cat > app/Models/Notification.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Notification extends Model{ protected $fillable=['user_id','type','title','body','is_read']; protected $casts=['is_read'=>'boolean']; }
PHP
cat > app/Models/NotificationSetting.php <<'PHP'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class NotificationSetting extends Model{ protected $fillable=['user_id','push_enabled','email_enabled','likes_enabled','comments_enabled','system_enabled']; protected $casts=['push_enabled'=>'boolean','email_enabled'=>'boolean','likes_enabled'=>'boolean','comments_enabled'=>'boolean','system_enabled'=>'boolean']; }
PHP

# === Миграции ===
mkdir -p database/migrations
cat > database/migrations/2025_08_18_000000_create_fishing_points_table.php <<'PHP'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('fishing_points', function (Blueprint $table) {
      $table->bigIncrements('id');
      $table->string('title');
      $table->text('description')->nullable();
      $table->enum('category',['spot','shop','slip','resort'])->default('spot');
      $table->double('lat',10,6);
      $table->double('lng',10,6);
      $table->boolean('is_public')->default(true);
      $table->boolean('is_highlighted')->default(false);
      $table->boolean('is_approved')->default(false);
      $table->string('photo_url')->nullable();
      $table->timestamps();
      $table->index(['category','is_public','is_approved']);
    });
  }
  public function down(): void { Schema::dropIfExists('fishing_points'); }
};
PHP

cat > database/migrations/2025_08_18_000100_create_catches_tables.php <<'PHP'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('catches', function (Blueprint $table) {
      $table->bigIncrements('id');
      $table->double('lat',10,6)->nullable();
      $table->double('lng',10,6)->nullable();
      $table->string('species')->nullable();
      $table->float('length')->nullable();
      $table->float('weight')->nullable();
      $table->float('depth')->nullable();
      $table->string('style',50)->nullable();
      $table->string('lure')->nullable();
      $table->string('tackle')->nullable();
      $table->string('privacy',20)->nullable()->default('all');
      $table->string('companions')->nullable();
      $table->text('notes')->nullable();
      $table->timestamp('caught_at')->nullable();
      $table->boolean('is_approved')->default(false);
      $table->timestamps();
    });
    Schema::create('catch_media', function (Blueprint $table) {
      $table->bigIncrements('id');
      $table->unsignedBigInteger('catch_id');
      $table->string('url');
      $table->string('type',20)->default('image');
      $table->timestamps();
      $table->foreign('catch_id')->references('id')->on('catches')->onDelete('cascade');
    });
  }
  public function down(): void {
    Schema::dropIfExists('catch_media');
    Schema::dropIfExists('catches');
  }
};
PHP

cat > database/migrations/2025_08_18_000200_create_events_clubs_tables.php <<'PHP'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('events', function (Blueprint $table) {
      $table->bigIncrements('id');
      $table->string('title');
      $table->string('region')->nullable();
      $table->timestamp('starts_at')->nullable();
      $table->timestamp('ends_at')->nullable();
      $table->text('description')->nullable();
      $table->double('location_lat',10,6)->nullable();
      $table->double('location_lng',10,6)->nullable();
      $table->string('link')->nullable();
      $table->string('photo_url')->nullable();
      $table->boolean('is_approved')->default(false);
      $table->timestamps();
    });
    Schema::create('clubs', function (Blueprint $table) {
      $table->bigIncrements('id');
      $table->string('name');
      $table->string('region')->nullable();
      $table->text('description')->nullable();
      $table->string('logo_url')->nullable();
      $table->boolean('is_approved')->default(false);
      $table->timestamps();
    });
  }
  public function down(): void {
    Schema::dropIfExists('clubs');
    Schema::dropIfExists('events');
  }
};
PHP

cat > database/migrations/2025_08_18_000300_create_billing_weather_notifications.php <<'PHP'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
  public function up(): void {
    Schema::create('plans', function (Blueprint $t) {
      $t->bigIncrements('id');
      $t->string('code')->unique();
      $t->string('title');
      $t->integer('price');
      $t->string('currency',10)->default('RUB');
      $t->string('interval',20)->default('month');
      $t->json('features')->nullable();
      $t->timestamps();
    });
    Schema::create('payments', function (Blueprint $t) {
      $t->bigIncrements('id');
      $t->unsignedBigInteger('user_id')->default(0);
      $t->string('provider',20);
      $t->string('status',20)->default('pending');
      $t->integer('amount');
      $t->string('currency',10)->default('RUB');
      $t->string('external_id')->nullable();
      $t->json('payload')->nullable();
      $t->timestamps();
    });
    Schema::create('weather_cache', function (Blueprint $t) {
      $t->bigIncrements('id');
      $t->string('key')->unique();
      $t->text('current')->nullable();
      $t->text('daily')->nullable();
      $t->timestamp('fetched_at');
      $t->timestamps();
    });
    Schema::create('notifications', function (Blueprint $t) {
      $t->bigIncrements('id');
      $t->unsignedBigInteger('user_id')->default(0);
      $t->string('type',30)->default('system');
      $t->string('title');
      $t->text('body')->nullable();
      $t->boolean('is_read')->default(false);
      $t->timestamps();
    });
    Schema::create('notification_settings', function (Blueprint $t) {
      $t->bigIncrements('id');
      $t->unsignedBigInteger('user_id')->default(0);
      $t->boolean('push_enabled')->default(false);
      $t->boolean('email_enabled')->default(true);
      $t->boolean('likes_enabled')->default(true);
      $t->boolean('comments_enabled')->default(true);
      $t->boolean('system_enabled')->default(true);
      $t->timestamps();
    });
  }
  public function down(): void {
    Schema::dropIfExists('notification_settings');
    Schema::dropIfExists('notifications');
    Schema::dropIfExists('weather_cache');
    Schema::dropIfExists('payments');
    Schema::dropIfExists('plans');
  }
};
PHP

# === Сидеры ===
mkdir -p database/seeders
cat > database/seeders/DatabaseSeeder.php <<'PHP'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
class DatabaseSeeder extends Seeder {
  public function run(): void {
    $this->call([ PlanSeeder::class, FishingPointSeeder::class, EventClubSeeder::class, CatchSeeder::class, AdminSeeder::class ]);
  }
}
PHP

cat > database/seeders/PlanSeeder.php <<'PHP'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\Plan;
class PlanSeeder extends Seeder {
  public function run(): void {
    Plan::updateOrCreate(['code'=>'pro_month'],['title'=>'Pro Месяц','price'=>299,'currency'=>'RUB','interval'=>'month','features'=>['Карты','Фильтры','Pro-бейдж']]);
    Plan::updateOrCreate(['code'=>'pro_year'],['title'=>'Pro Год','price'=>2490,'currency'=>'RUB','interval'=>'year','features'=>['Экономия 20%']]);
  }
}
PHP

cat > database/seeders/FishingPointSeeder.php <<'PHP'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\FishingPoint;
class FishingPointSeeder extends Seeder {
  public function run(): void {
    $cats=['spot','shop','slip','resort'];
    for($i=1;$i<=120;$i++){
      FishingPoint::create([
        'title'=>"Demo {$cats[$i%4]} #$i",
        'description'=>'Демо-точка',
        'category'=>$cats[$i%4],
        'lat'=>55.75+(mt_rand(-300,300)/1000.0),
        'lng'=>37.62+(mt_rand(-500,500)/1000.0),
        'is_public'=>true,
        'is_highlighted'=>$i%11===0,
        'photo_url'=>null,
        'is_approved'=>true,
      ]);
    }
  }
}
PHP

cat > database/seeders/EventClubSeeder.php <<'PHP'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\Event;
use App\Models\Club;
class EventClubSeeder extends Seeder {
  public function run(): void {
    for($i=1;$i<=40;$i++){
      Event::create([
        'title'=>"Соревнование #$i",'region'=>'RU-MOW',
        'starts_at'=>now()->addDays($i),'ends_at'=>now()->addDays($i+1),
        'description'=>"Описание события #$i",
        'location_lat'=>55.75+(mt_rand(-200,200)/1000.0),
        'location_lng'=>37.62+(mt_rand(-300,300)/1000.0),
        'link'=>"https://example.com/event/$i",'photo_url'=>null,'is_approved'=>true,
      ]);
    }
    for($i=1;$i<=40;$i++){
      Club::create([ 'name'=>"Клуб #$i",'region'=>'RU-MOW','description'=>"Описание клуба #$i",'logo_url'=>null,'is_approved'=>true ]);
    }
  }
}
PHP

cat > database/seeders/CatchSeeder.php <<'PHP'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\CatchRecord;
class CatchSeeder extends Seeder {
  public function run(): void {
    for($i=1;$i<=140;$i++){
      CatchRecord::create([
        'lat'=>55.75+(mt_rand(-300,300)/1000.0),
        'lng'=>37.62+(mt_rand(-500,500)/1000.0),
        'species'=>'Щука','length'=>mt_rand(20,120),'weight'=>mt_rand(1,12),'depth'=>mt_rand(1,15),
        'style'=>'берег','lure'=>'Воблер','tackle'=>'Спиннинг',
        'privacy'=>'all','companions'=>'Иван, Пётр','notes'=>'Демо-запись',
        'caught_at'=>now()->subDays(mt_rand(0,120)),'is_approved'=>true,
      ]);
    }
  }
}
PHP

cat > database/seeders/AdminSeeder.php <<'PHP'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Models\User;
class AdminSeeder extends Seeder {
  public function run(): void {
    $email=env('ADMIN_EMAIL','admin@fishtrackpro.local'); $pass=env('ADMIN_PASSWORD','admin123');
    if (class_exists(User::class)) {
      User::updateOrCreate(['email'=>$email],[ 'name'=>'Admin','password'=>Hash::make($pass),'remember_token'=>Str::random(10) ]);
    }
  }
}
PHP

# === Планировщик (опционально) ===
mkdir -p app/Console
cat > app/Console/Kernel.php <<'PHP'
<?php
namespace App\Console;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;
class Kernel extends ConsoleKernel {
  protected function schedule(Schedule $s): void {
    $s->call(fn()=>\Log::info('daily_digest'))->dailyAt('08:00');
    $s->call(fn()=>\Log::info('recalculate_ratings'))->hourly();
    $s->call(fn()=>\Log::info('renew_subscriptions'))->dailyAt('03:00');
  }
  protected function commands(): void { $this->load(__DIR__.'/Commands'); require base_path('routes/console.php'); }
}
PHP

# === Линки и оптимизация, миграции/сиды ===
php artisan storage:link || true
php artisan optimize
php artisan migrate --force
php artisan db:seed --class=DatabaseSeeder --force

echo "✅ Готово. Тест:"
php -S 127.0.0.1:8000 -t public >/dev/null 2>&1 & sleep 1
curl -s http://127.0.0.1:8000/api/health || true
echo
echo "➡️  Запуск вручную: php artisan serve --host=127.0.0.1 --port=8000"
