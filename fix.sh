#!/usr/bin/env bash
set -euo pipefail

FRONTEND_DIR="frontend"
SRC="$FRONTEND_DIR/src"

[ -d "$SRC" ] || { echo "❌ Не найден каталог $SRC (запусти из корня проекта)"; exit 1; }

# 1) Пересобираем src/api.ts под /api/v1 и явные экспорты
cat > "$SRC/api.ts" <<'TS'
import cfgDefault, { config as cfgNamed } from './config';

const cfg = (cfgNamed ?? cfgDefault);

/** Базовый fetch с общими заголовками/куками и автообработкой ошибок */
async function http<T = any>(path: string, init: RequestInit = {}): Promise<T> {
  const base = cfg.apiBase?.replace(/\/+$/,'') || '';
  const url  = `${base}${path.startsWith('/') ? '' : '/'}${path}`;
  const headers: HeadersInit = {
    Accept: 'application/json',
    ...(init.body ? {'Content-Type':'application/json'} : {}),
    ...(init.headers || {}),
  };
  const res = await fetch(url, {
    method: init.method ?? 'GET',
    credentials: 'include',             // важно для сессии
    headers,
    body: init.body as any,
  });

  // Иногда бек может прислать 204 без тела
  if (res.status === 204) return undefined as any;

  let data: any = null;
  const text = await res.text();
  try { data = text ? JSON.parse(text) : null; } catch { data = text; }

  if (!res.ok) {
    const msg = (data && (data.message || data.error)) || res.statusText;
    const err: any = new Error(`HTTP ${res.status}: ${msg}`);
    err.status = res.status;
    err.data = data;
    throw err;
  }
  return data as T;
}

/** Лента */
export async function feed(params: { limit?: number; offset?: number } = {}) {
  const q = new URLSearchParams();
  if (params.limit  != null) q.set('limit',  String(params.limit));
  if (params.offset != null) q.set('offset', String(params.offset));
  return http<{ items: any[]; nextOffset?: number }>(`/feed?${q.toString()}`);
}

/** Точки карты */
export async function points(params: { limit?: number; bbox?: string; filter?: string } = {}) {
  const q = new URLSearchParams();
  if (params.limit  != null) q.set('limit',  String(params.limit));
  if (params.bbox)           q.set('bbox',   params.bbox);
  if (params.filter)         q.set('filter', params.filter);
  return http<any[]>(`/map/points?${q.toString()}`);
}

/** Профиль */
export async function getProfile() {
  return http(`/profile/me`);
}

/** Уведомления */
export async function getNotifications() {
  return http<any[]>(`/notifications`);
}

/** Деталь улова */
export async function getCatchById(id: string|number) {
  return http(`/catch/${id}`);
}

/** Комментарий к улову */
export async function addComment(catchId: string|number, payload: { text: string }) {
  return http(`/catch/${catchId}/comments`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

/** Создать место */
export async function addPlace(payload: {
  lat: number; lng: number; title: string; description?: string; photos?: string[];
}) {
  return http(`/points`, { method:'POST', body: JSON.stringify(payload) });
}

/** Создать улов */
export async function addCatch(payload: {
  lat: number; lng: number; species?: string; length?: number; weight?: number;
  method?: string; bait?: string; gear?: string; caption?: string; photo_url?: string;
  caught_at?: string; privacy?: 'all'|'friends'|'private';
}) {
  return http(`/catch`, { method:'POST', body: JSON.stringify(payload) });
}

/** Избранные погодные точки (храним на бек/или локально — фронт прозрачен) */
export async function getWeatherFavs() {
  try {
    return await http<{ id:string; lat:number; lng:number; name:string }[]>(`/weather/favs`);
  } catch (e:any) {
    // fallback на localStorage, если ендпоинта нет
    const raw = localStorage.getItem('weather_favs') || '[]';
    return JSON.parse(raw);
  }
}
export async function saveWeatherFav(fav: { id?:string; lat:number; lng:number; name:string }) {
  try {
    return await http(`/weather/favs`, { method:'POST', body: JSON.stringify(fav) });
  } catch (e:any) {
    const list = await getWeatherFavs();
    const withId = { ...fav, id: fav.id || String(Date.now()) };
    const next = [withId, ...list.filter((x:any)=>x.id!==withId.id)];
    localStorage.setItem('weather_favs', JSON.stringify(next));
    return withId;
  }
}

/** Техническая проверка доступности API */
export async function ping() {
  try {
    // если есть /health — отлично, иначе быстрая заглушка к /feed с нулевыми лимитами
    const res = await http(`/health`).catch(() => http(`/feed?limit=1&offset=0`));
    return { ok: true, res };
  } catch (e:any) {
    return { ok: false, error: e?.message || String(e) };
  }
}

export default {
  feed,
  points,
  getProfile,
  getNotifications,
  getCatchById,
  addComment,
  addPlace,
  addCatch,
  getWeatherFavs,
  saveWeatherFav,
  ping,
};
TS

echo "✅ Обновлён $SRC/api.ts"

# 2) Включаем лёгкий fetch-логгер (только в dev) + подключаем его в main.tsx
mkdir -p "$SRC/utils"

cat > "$SRC/utils/fetchDebug.ts" <<'TS'
/**
 * Примитивный логгер fetch для dev.
 * В проде не активируется (NODE_ENV !== 'development').
 */
if (import.meta && import.meta.env && import.meta.env.DEV) {
  const orig = window.fetch;
  window.fetch = async (input: RequestInfo | URL, init?: RequestInit) => {
    const method = (init?.method || 'GET').toUpperCase();
    const url = typeof input === 'string' ? input : (input as URL).toString();
    // eslint-disable-next-line no-console
    console.debug('🛰️ fetch →', method, url, init?.body ? 'with body' : '');
    const t0 = performance.now();
    try {
      const res = await orig(input, init);
      const dt = (performance.now() - t0).toFixed(0);
      // eslint-disable-next-line no-console
      console.debug('✅ fetch ←', res.status, method, url, `${dt}ms`);
      return res;
    } catch (e:any) {
      const dt = (performance.now() - t0).toFixed(0);
      // eslint-disable-next-line no-console
      console.debug('❌ fetch ×', method, url, `${dt}ms`, e?.message || e);
      throw e;
    }
  };
}
export {};
TS

# Вставляем импорт логгера в начало main.tsx (если его ещё нет)
MAIN="$SRC/main.tsx"
if [ -f "$MAIN" ]; then
  if ! grep -q "utils/fetchDebug" "$MAIN"; then
    # macOS-портативная вставка: создаём временный файл
    TMP="$(mktemp)"
    echo "import './utils/fetchDebug';" > "$TMP"
    cat "$MAIN" >> "$TMP"
    mv "$TMP" "$MAIN"
    echo "🔎 Добавлен dev-логгер fetch в $MAIN"
  fi
fi

echo "🎯 Готово. Теперь сборка и проверка сетевых вызовов:"
echo "   cd $FRONTEND_DIR && npm run dev   # dev: смотри консоль — должны пойти запросы"
echo "   cd $FRONTEND_DIR && npm run build # prod: проверка успешной сборки"