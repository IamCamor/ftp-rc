#!/usr/bin/env bash
set -euo pipefail

ROOT="fishtrackpro_ai_patch"
ZIP="${ROOT}.zip"

rm -rf "$ROOT" "$ZIP"
mkdir -p \
  "$ROOT/backend/app/Services/Moderation/Providers" \
  "$ROOT/backend/app/Http/Controllers/Api" \
  "$ROOT/backend/config" \
  "$ROOT/backend/sql" \
  "$ROOT/frontend/src/{api,screens}"

########################################
# CONFIG: config/moderation.php
########################################
cat > "$ROOT/backend/config/moderation.php" <<'PHP'
<?php
return [
    // Драйвер: 'none' | 'heuristic' | 'openai' | 'yandex'
    'driver' => env('MODERATION_DRIVER', 'heuristic'),

    // Общие лимиты
    'timeout' => env('MODERATION_TIMEOUT', 6), // сек

    // OpenAI
    'openai' => [
        'api_key' => env('OPENAI_API_KEY'),
        // Для строгой модерации используем специальную модель модерации
        'model'   => env('OPENAI_MODERATION_MODEL', 'omni-moderation-latest'),
        'endpoint'=> env('OPENAI_MODERATION_ENDPOINT','https://api.openai.com/v1/moderations'),
    ],

    // Yandex Cloud / YandexGPT
    'yandex' => [
        // OAuth-токен сервисного аккаунта или IAM токен
        'oauth_token' => env('YC_OAUTH_TOKEN'),
        'folder_id'   => env('YC_FOLDER_ID'),
        // Модель для классификации (легкая и недорогая)
        'model'       => env('YC_MODEL', 'yandexgpt-lite'),
        // endpoint для v1/completion
        'endpoint'    => env('YC_ENDPOINT','https://llm.api.cloud.yandex.net/foundationModels/v1/completion'),
    ],
];
PHP

########################################
# SERVICE + PROVIDERS
########################################
cat > "$ROOT/backend/app/Services/Moderation/AiModeration.php" <<'PHP'
<?php
namespace App\Services\Moderation;

use App\Services\Moderation\Providers\HeuristicProvider;
use App\Services\Moderation\Providers\OpenAIProvider;
use App\Services\Moderation\Providers\YandexGPTProvider;

class AiModeration
{
    public static function check(?string $text): array
    {
        if (!$text || trim($text)==='') {
            return ['approved'=>true, 'labels'=>[], 'reason'=>null, 'provider'=>'skip'];
        }

        $driver = config('moderation.driver','heuristic');
        $timeout = (int) config('moderation.timeout', 6);

        $provider = match($driver) {
            'openai'  => new OpenAIProvider(config('moderation.openai'), $timeout),
            'yandex'  => new YandexGPTProvider(config('moderation.yandex'), $timeout),
            'none'    => new HeuristicProvider([], $timeout, true),
            default   => new HeuristicProvider([], $timeout, false),
        };

        try {
            $res = $provider->checkText($text);
            // приведение к единому формату
            return [
                'approved' => (bool)($res['approved'] ?? true),
                'labels'   => $res['labels']   ?? [],
                'reason'   => $res['reason']   ?? null,
                'provider' => $res['provider'] ?? $driver,
                'raw'      => $res['raw']      ?? null,
            ];
        } catch (\Throwable $e) {
            // Если провайдер упал — НЕ блочим, пропускаем
            return ['approved'=>true,'labels'=>[],'reason'=>'provider_failed','provider'=>$driver];
        }
    }
}
PHP

cat > "$ROOT/backend/app/Services/Moderation/Providers/HeuristicProvider.php" <<'PHP'
<?php
namespace App\Services\Moderation\Providers;

class HeuristicProvider
{
    protected bool $alwaysApprove;
    protected int $timeout;
    public function __construct(array $cfg=[], int $timeout=6, bool $alwaysApprove=false)
    {
        $this->timeout = $timeout;
        $this->alwaysApprove = $alwaysApprove;
    }

    public function checkText(string $text): array
    {
        if ($this->alwaysApprove) {
            return ['approved'=>true, 'labels'=>[], 'reason'=>'disabled', 'provider'=>'heuristic'];
        }
        $bad = (bool) preg_match('/\b(спам|оскорб|мат|ненависть|суицид|наркот|расизм|фашизм)\b/iu', $text);
        return [
            'approved'=> !$bad,
            'labels'  => $bad ? ['toxic'] : [],
            'reason'  => $bad ? 'heuristic_badword' : 'ok',
            'provider'=> 'heuristic',
        ];
    }
}
PHP

cat > "$ROOT/backend/app/Services/Moderation/Providers/OpenAIProvider.php" <<'PHP'
<?php
namespace App\Services\Moderation\Providers;

use GuzzleHttp\Client;

class OpenAIProvider
{
    protected array $cfg;
    protected int $timeout;
    public function __construct(array $cfg, int $timeout=6)
    {
        $this->cfg = $cfg;
        $this->timeout = $timeout;
    }

    public function checkText(string $text): array
    {
        if (empty($this->cfg['api_key'])) {
            throw new \RuntimeException('OPENAI_API_KEY missing');
        }
        $client = new Client([
            'timeout' => $this->timeout,
        ]);

        $resp = $client->post($this->cfg['endpoint'] ?? 'https://api.openai.com/v1/moderations', [
            'headers' => [
                'Authorization' => 'Bearer '.$this->cfg['api_key'],
                'Content-Type'  => 'application/json',
            ],
            'json' => [
                'model' => $this->cfg['model'] ?? 'omni-moderation-latest',
                'input' => $text,
            ],
        ]);

        $json = json_decode((string)$resp->getBody(), true);
        // Формат OpenAI moderation: categories + flagged
        $result = $json['results'][0] ?? [];
        $flagged = (bool)($result['flagged'] ?? false);
        $labels = [];
        if (!empty($result['categories'])) {
            foreach ($result['categories'] as $k=>$v) {
                if ($v) $labels[] = $k;
            }
        }
        return [
            'approved'=> !$flagged,
            'labels'  => $labels,
            'reason'  => $flagged ? 'openai_flagged' : 'openai_ok',
            'provider'=> 'openai',
            'raw'     => $json,
        ];
    }
}
PHP

cat > "$ROOT/backend/app/Services/Moderation/Providers/YandexGPTProvider.php" <<'PHP'
<?php
namespace App\Services\Moderation\Providers;

use GuzzleHttp\Client;

/**
 * Простой prompt-классификатор через YandexGPT.
 * Возвращает JSON с approved/labels. Если парсинг не удался — разрешаем (fail-open).
 */
class YandexGPTProvider
{
    protected array $cfg;
    protected int $timeout;
    public function __construct(array $cfg, int $timeout=6)
    {
        $this->cfg = $cfg;
        $this->timeout = $timeout;
    }

    public function checkText(string $text): array
    {
        if (empty($this->cfg['oauth_token']) || empty($this->cfg['folder_id'])) {
            throw new \RuntimeException('YC_OAUTH_TOKEN or YC_FOLDER_ID missing');
        }

        $prompt = <<<EOT
Ты — фильтр модерации. Классифицируй текст пользователя. Ответь строго JSON без пояснений:
{"approved":true|false,"labels":["..."],"reason":"кратко"}

Правила отклонения: оскорбления/ненависть/расизм/насилие/суицид/наркотики/спам/NSFW.
Текст: <<<{$text}>>>
EOT;

        $client = new Client(['timeout'=>$this->timeout]);
        $resp = $client->post($this->cfg['endpoint'] ?? 'https://llm.api.cloud.yandex.net/foundationModels/v1/completion', [
            'headers' => [
                'Authorization' => 'Bearer '.$this->cfg['oauth_token'],
                'x-folder-id'   => $this->cfg['folder_id'],
                'Content-Type'  => 'application/json',
            ],
            'json' => [
                'model' => ($this->cfg['model'] ?? 'yandexgpt-lite').'/latest',
                'completionOptions' => [
                    'stream' => false,
                    'temperature' => 0.0,
                    'maxTokens' => 256
                ],
                'messages' => [
                    ['role'=>'system','text'=>'Ты помощник модерации. Отвечай строго JSON.'],
                    ['role'=>'user','text'=>$prompt],
                ],
            ],
        ]);

        $json = json_decode((string)$resp->getBody(), true);
        $textOut = $json['result']['alternatives'][0]['message']['text'] ?? '';
        // Попробуем распарсить JSON из ответа
        $parsed = null;
        if ($textOut) {
            $textOut = trim($textOut);
            // на случай, если модель добавила пояснения
            $start = strpos($textOut, '{');
            $end   = strrpos($textOut, '}');
            if ($start!==false && $end!==false && $end>$start) {
                $maybe = substr($textOut, $start, $end-$start+1);
                $parsed = json_decode($maybe, true);
            }
        }

        if (is_array($parsed) && isset($parsed['approved'])) {
            return [
                'approved'=> (bool)$parsed['approved'],
                'labels'  => array_values((array)($parsed['labels'] ?? [])),
                'reason'  => $parsed['reason'] ?? 'yandex_ok',
                'provider'=> 'yandex',
                'raw'     => $json,
            ];
        }

        // fail-open
        return [
            'approved'=> true,
            'labels'  => [],
            'reason'  => 'yandex_parse_fallback',
            'provider'=> 'yandex',
            'raw'     => $json,
        ];
    }
}
PHP

########################################
# API ДОПОЛНЕНИЯ (как раньше): репорты/погода/лидерборды
########################################
cat > "$ROOT/backend/app/Http/Controllers/Api/WeatherLocationsController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WeatherLocationsController extends Controller
{
    public function index(Request $r) {
        $uid = auth()->id();
        $rows = DB::table('user_weather_locations')
            ->where(function($q) use ($uid){ $q->where('user_id', $uid ?? 0); })
            ->orderBy('pos')->orderBy('id')->get();
        return response()->json(['items'=>$rows]);
    }
    public function store(Request $r) {
        $uid = auth()->id() ?? 0;
        $data = $r->validate([
            'name'=>'required|string|min:2',
            'lat'=>'required|numeric',
            'lng'=>'required|numeric',
            'pos'=>'nullable|integer',
        ]);
        $id = DB::table('user_weather_locations')->insertGetId(array_merge($data,[
            'user_id'=>$uid, 'created_at'=>now(),'updated_at'=>now()
        ]));
        return response()->json(['id'=>$id],201);
    }
    public function destroy($id) {
        $uid = auth()->id() ?? 0;
        DB::table('user_weather_locations')->where('id',$id)->where('user_id',$uid)->delete();
        return response()->json(['ok'=>true]);
    }
}
PHP

cat > "$ROOT/backend/app/Http/Controllers/Api/LeaderboardController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LeaderboardController extends Controller
{
    public function index(Request $r) {
        $period = $r->query('period','weekly');
        [$from,$to] = match($period){
            'daily'   => [now()->startOfDay(),   now()->endOfDay()],
            'monthly' => [now()->startOfMonth(), now()->endOfMonth()],
            default   => [now()->startOfWeek(),  now()->endOfWeek()],
        };
        $metric = $r->query('metric','likes');

        if ($metric==='catches') {
            $rows = DB::table('catch_records as cr')
                ->selectRaw('cr.user_id, u.name, COALESCE(u.photo_url,"") as avatar, COUNT(*) as value')
                ->leftJoin('users as u','u.id','=','cr.user_id')
                ->whereBetween('cr.created_at',[$from,$to])
                ->where('cr.privacy','!=','private')
                ->groupBy('cr.user_id','u.name','u.photo_url')
                ->orderByDesc('value')->limit(100)->get();
        } else {
            $rows = DB::table('catch_likes as cl')
                ->selectRaw('cr.user_id, u.name, COALESCE(u.photo_url,"") as avatar, COUNT(*) as value')
                ->join('catch_records as cr','cr.id','=','cl.catch_id')
                ->leftJoin('users as u','u.id','=','cr.user_id')
                ->whereBetween('cl.created_at',[$from,$to])
                ->where('cr.privacy','!=','private')
                ->groupBy('cr.user_id','u.name','u.photo_url')
                ->orderByDesc('value')->limit(100)->get();
        }
        return response()->json(['period'=>$period,'metric'=>$metric,'items'=>$rows]);
    }
}
PHP

cat > "$ROOT/backend/app/Http/Controllers/Api/ReportController.php" <<'PHP'
<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function store(Request $r) {
        $data = $r->validate([
            'target_type'=>'required|in:catch,comment,user,point',
            'target_id'  =>'required|integer',
            'reason'     =>'nullable|string|max:2000',
        ]);
        $id = DB::table('reports')->insertGetId([
            'user_id'     => auth()->id(),
            'target_type' => $data['target_type'],
            'target_id'   => $data['target_id'],
            'reason'      => $data['reason'] ?? null,
            'status'      => 'new',
            'created_at'  => now(),
            'updated_at'  => now(),
        ]);
        return response()->json(['id'=>$id],201);
    }
}
PHP

########################################
# SQL (как и раньше, без миграций)
########################################
cat > "$ROOT/backend/sql/patch_ai_weather_leaderboard.sql" <<'SQL'
-- Сохранённых локаций для погоды может не быть
CREATE TABLE IF NOT EXISTS user_weather_locations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL DEFAULT 0,
  name VARCHAR(255) NOT NULL,
  lat DOUBLE NOT NULL,
  lng DOUBLE NOT NULL,
  pos INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  INDEX (user_id)
);

-- Жалобы
CREATE TABLE IF NOT EXISTS reports (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  target_type VARCHAR(32) NOT NULL,
  target_id BIGINT UNSIGNED NOT NULL,
  reason TEXT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'new',
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  INDEX(target_type, target_id)
);

-- Флаг модерации для комментариев, если нет
ALTER TABLE catch_comments
  ADD COLUMN IF NOT EXISTS is_approved TINYINT(1) NOT NULL DEFAULT 1;
SQL

########################################
# FRONT: helper для репортов/погоды/лидера
########################################
cat > "$ROOT/frontend/src/api/extra.ts" <<'TS'
export const API = (window as any).__API_BASE__ || "https://api.fishtrackpro.ru/api";

async function _req(method: string, url: string, body?: any) {
  const init: RequestInit = {
    method, credentials: "include",
    headers: {"Content-Type":"application/json"}
  };
  if (body) init.body = JSON.stringify(body);
  const res = await fetch(url, init);
  if (!res.ok) throw new Error(`${method} ${url} -> ${res.status}`);
  return res.json();
}

export const listWeatherLocations = () => _req('GET', `${API}/v1/weather/locations`);
export const addWeatherLocation    = (data:any) => _req('POST', `${API}/v1/weather/locations`, data);
export const removeWeatherLocation = (id:number) => _req('DELETE', `${API}/v1/weather/locations/${id}`);

export const getWeather = (lat:number, lng:number, dt?:number) =>
  _req('GET', `${API}/v1/weather?lat=${lat}&lng=${lng}${dt?`&dt=${dt}`:''}`);

export const getLeaderboard = (period:'daily'|'weekly'|'monthly'='weekly', metric:'likes'|'catches'='likes') =>
  _req('GET', `${API}/v1/leaderboard?period=${period}&metric=${metric}`);

export const sendReport = (target_type:'catch'|'comment'|'user'|'point', target_id:number, reason?:string) =>
  _req('POST', `${API}/v1/report`, { target_type, target_id, reason });
TS

########################################
# FRONT: Weather / Leaderboard (экраны)
########################################
cat > "$ROOT/frontend/src/screens/WeatherPage.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { listWeatherLocations, addWeatherLocation, removeWeatherLocation, getWeather } from "../api/extra";

type Loc = { id:number; name:string; lat:number; lng:number; pos:number };

export default function WeatherPage(){
  const [items, setItems] = useState<Loc[]>([]);
  const [form, setForm] = useState({ name:"", lat:"", lng:"" });
  const [adding, setAdding] = useState(false);
  const [wx, setWx] = useState<Record<number, any>>({});

  useEffect(()=>{ (async ()=>{
    try {
      const r = await listWeatherLocations();
      const arr:Loc[] = r.items || [];
      setItems(arr);
      for (const it of arr) {
        const w = await getWeather(it.lat,it.lng).catch(()=>null);
        if (w) setWx(s=>({...s,[it.id]:w}));
      }
    } catch(e){}
  })(); }, []);

  const onAdd = async (e:React.FormEvent)=> {
    e.preventDefault();
    const lat = parseFloat(form.lat); const lng = parseFloat(form.lng);
    if (!form.name || Number.isNaN(lat) || Number.isNaN(lng)) return;
    const r = await addWeatherLocation({name:form.name, lat, lng});
    const id = r.id;
    const w = await getWeather(lat,lng).catch(()=>null);
    setItems(s=>[...s, {id, name:form.name, lat, lng, pos:0}]);
    if (w) setWx(s=>({...s,[id]:w}));
    setForm({name:"",lat:"",lng:""}); setAdding(false);
  };

  const onDelete = async (id:number)=>{
    await removeWeatherLocation(id);
    setItems(s=>s.filter(i=>i.id!==id));
  };

  return (
    <div className="p-4 space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold">Погода</h1>
        <button onClick={()=>setAdding(true)} className="px-3 py-2 rounded-xl bg-white/60 backdrop-blur border">+ Локация</button>
      </div>

      {adding && (
        <form onSubmit={onAdd} className="grid gap-2 p-3 rounded-2xl bg-white/60 backdrop-blur border">
          <input className="px-3 py-2 rounded-xl border" placeholder="Название" value={form.name} onChange={e=>setForm({...form, name:e.target.value})}/>
          <div className="grid grid-cols-2 gap-2">
            <input className="px-3 py-2 rounded-xl border" placeholder="Широта" value={form.lat} onChange={e=>setForm({...form, lat:e.target.value})}/>
            <input className="px-3 py-2 rounded-xl border" placeholder="Долгота" value={form.lng} onChange={e=>setForm({...form, lng:e.target.value})}/>
          </div>
          <div className="flex gap-2">
            <button className="px-3 py-2 rounded-xl bg-blue-500 text-white">Сохранить</button>
            <button type="button" onClick={()=>setAdding(false)} className="px-3 py-2 rounded-xl">Отмена</button>
          </div>
        </form>
      )}

      <div className="space-y-3">
        {items.map(it=>{
          const w = wx[it.id];
          const temp = w?.ok ? (w.current?.temp ?? w.hourly?.[0]?.temp) : null;
          const wind = w?.ok ? (w.current?.wind_speed ?? w.hourly?.[0]?.wind_speed) : null;
          return (
            <div key={it.id} className="p-4 rounded-2xl bg-white/60 backdrop-blur border flex items-center justify-between">
              <div>
                <div className="font-medium">{it.name}</div>
                <div className="text-sm text-gray-600">{it.lat.toFixed(3)}, {it.lng.toFixed(3)}</div>
                <div className="text-sm mt-1">{temp!=null ? `Темп: ${Math.round(temp)}°C` : 'Нет данных'}{wind!=null ? ` · Ветер: ${Math.round(wind)} м/с` : ''}</div>
              </div>
              <button onClick={()=>onDelete(it.id)} className="px-3 py-2 rounded-xl border">Удалить</button>
            </div>
          );
        })}
        {!items.length && <div className="text-center text-gray-500">Нет сохранённых локаций</div>}
      </div>
    </div>
  );
}
TSX

cat > "$ROOT/frontend/src/screens/LeaderboardPage.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { getLeaderboard } from "../api/extra";

type Period = 'daily'|'weekly'|'monthly';
type Metric = 'likes'|'catches';

export default function LeaderboardPage(){
  const [period,setPeriod] = useState<Period>('weekly');
  const [metric,setMetric] = useState<Metric>('likes');
  const [items,setItems] = useState<any[]>([]);
  const [loading,setLoading] = useState(true);

  useEffect(()=>{ (async ()=>{
    setLoading(true);
    try{
      const r = await getLeaderboard(period,metric);
      setItems(r.items||[]);
    }catch(e){}
    setLoading(false);
  })(); }, [period,metric]);

  return (
    <div className="p-4 space-y-3">
      <h1 className="text-xl font-semibold">Рейтинг</h1>
      <div className="flex gap-2 items-center">
        {(['daily','weekly','monthly'] as Period[]).map(p=>{
          const active = p===period;
          return <button key={p} onClick={()=>setPeriod(p)} className={`px-3 py-2 rounded-xl border ${active?'bg-blue-500 text-white':'bg-white/60 backdrop-blur'}`}>{p==='daily'?'день':p==='weekly'?'неделя':'месяц'}</button>;
        })}
        <div className="flex-1" />
        {(['likes','catches'] as Metric[]).map(m=>{
          const active = m===metric;
          return <button key={m} onClick={()=>setMetric(m)} className={`px-3 py-2 rounded-xl border ${active?'bg-blue-500 text-white':'bg-white/60 backdrop-blur'}`}>{m==='likes'?'лайки':'уловы'}</button>;
        })}
      </div>

      {loading && <div className="text-gray-500">Загрузка…</div>}
      {!loading && !items.length && <div className="text-gray-500">Пусто</div>}

      <div className="space-y-2">
        {items.map((it,idx)=>(
          <div key={idx} className="p-3 rounded-2xl bg-white/60 backdrop-blur border flex items-center gap-3">
            <img src={it.avatar||''} onError={(e:any)=>e.currentTarget.style.display='none'} className="w-10 h-10 rounded-full object-cover"/>
            <div className="flex-1">
              <div className="font-medium">{it.name||'—'}</div>
              <div className="text-sm text-gray-600">Баллы: {it.value}</div>
            </div>
            <a href={`#/profile/${it.user_id}`} className="px-3 py-2 rounded-xl border">Профиль</a>
          </div>
        ))}
      </div>
    </div>
  );
}
TSX

########################################
# README
########################################
cat > "$ROOT/README.md" <<'MD'
# FishTrackPro — AI Moderation Patch (OpenAI + YandexGPT) + Weather locations + Leaderboard + Reports

Архив содержит **готовые файлы**, ничего не перезаписывает автоматически. Вы сами копируете их в проект.

## Что внутри

### Backend
- `config/moderation.php` — единый конфиг AI-модерации:
  - `MODERATION_DRIVER=none|heuristic|openai|yandex`
  - OpenAI: `OPENAI_API_KEY`, `OPENAI_MODERATION_MODEL` (по умолчанию `omni-moderation-latest`)
  - YandexGPT: `YC_OAUTH_TOKEN`, `YC_FOLDER_ID`, `YC_MODEL` (`yandexgpt-lite` по умолчанию), `YC_ENDPOINT`
- `app/Services/Moderation/*` — сервис `AiModeration` и провайдеры:
  - `OpenAIProvider` — POST `/v1/moderations`
  - `YandexGPTProvider` — `/foundationModels/v1/completion` с JSON-ответом
  - `HeuristicProvider` — простая эвристика/заглушка
- Контроллеры: `WeatherLocationsController`, `LeaderboardController`, `ReportController`
- SQL: `backend/sql/patch_ai_weather_leaderboard.sql` (без миграций)

**Подключение роутов** (внутрь вашей группы `/api/v1`, ничего не удаляя):
```php
use App\Http\Controllers\Api\WeatherLocationsController;
use App\Http\Controllers\Api\LeaderboardController;
use App\Http\Controllers\Api\ReportController;

Route::get('/weather/locations', [WeatherLocationsController::class,'index']);
Route::middleware('auth:sanctum')->group(function(){
  Route::post('/weather/locations', [WeatherLocationsController::class,'store']);
  Route::delete('/weather/locations/{id}', [WeatherLocationsController::class,'destroy']);
});

Route::get('/leaderboard', [LeaderboardController::class,'index']);
Route::post('/report', [ReportController::class,'store']);