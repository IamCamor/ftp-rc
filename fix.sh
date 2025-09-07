#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
API_FILE="$ROOT/frontend/src/api.ts"

if [ ! -d "$ROOT/frontend/src" ]; then
  echo "❌ Запусти из корня репо (где есть frontend/src)"
  exit 1
fi

echo "→ Обновляю $API_FILE"

cat > "$API_FILE" <<'TS'
// Унифицированный API-клиент для фронта.
// Важно: CORS не трогаем (работает на бэке).

import config from './config';

type Json = any;

const apiBase =
  (config as any)?.api?.v1Base ??
  (config as any)?.apiBase ??
  (config as any)?.api?.base ??
  '/api/v1';

function normUrl(path: string) {
  if (!path.startsWith('/')) path = '/' + path;
  // если apiBase уже содержит /api/v1 — не дублируем
  if (apiBase.endsWith('/')) return apiBase.replace(/\/+$/,'') + path;
  return apiBase + path;
}

async function req<T = Json>(
  path: string,
  opts: RequestInit & { auth?: boolean; formData?: boolean } = {}
): Promise<T> {
  const url = normUrl(path);
  const headers: Record<string, string> = { Accept: 'application/json' };

  const token = localStorage.getItem('token');
  if (opts.auth && token) headers['Authorization'] = `Bearer ${token}`;

  let body: BodyInit | undefined = opts.body as any;
  if (!opts.formData && body && typeof body === 'object') {
    headers['Content-Type'] = 'application/json';
    body = JSON.stringify(body);
  }

  const res = await fetch(url, {
    method: opts.method || 'GET',
    credentials: 'include',
    headers,
    body,
    cache: 'no-store',
  });

  if (!res.ok) {
    // Попробуем отдать JSON с ошибкой
    let err: any = null;
    try { err = await res.json(); } catch {}
    const msg = err?.message || `HTTP ${res.status}`;
    throw new Error(msg);
  }

  // Пустой ответ
  if (res.status === 204) return null as T;

  // JSON или пусто
  const text = await res.text();
  if (!text) return null as T;

  try {
    return JSON.parse(text) as T;
  } catch {
    // Если не JSON — вернём как есть
    return (text as unknown) as T;
  }
}

/** ====== FEED ====== */
export async function feed(params: { limit?: number; offset?: number } = {}) {
  const q = new URLSearchParams();
  if (params.limit != null) q.set('limit', String(params.limit));
  if (params.offset != null) q.set('offset', String(params.offset));
  const path = `/feed${q.toString() ? `?${q.toString()}` : ''}`;
  return req(path, { auth: true });
}

export async function catchById(id: number | string) {
  return req(`/catch/${id}`, { auth: true });
}

export async function addComment(catchId: number | string, text: string) {
  return req(`/catch/${catchId}/comments`, {
    method: 'POST',
    auth: true,
    body: { text },
  });
}

// Лайк улова
export async function likeCatch(catchId: number | string) {
  return req(`/catch/${catchId}/like`, { method: 'POST', auth: true });
}

// Рейтинг улова (звёзды и т.п.)
export async function rateCatch(catchId: number | string, value: number) {
  return req(`/catch/${catchId}/rate`, {
    method: 'POST',
    auth: true,
    body: { value },
  });
}

// Начисление бонусов (по действию)
export async function bonusAward(action: string, payload: Record<string, any> = {}) {
  return req(`/bonus/award`, {
    method: 'POST',
    auth: true,
    body: { action, ...payload },
  });
}

/** ====== MAP / POINTS ====== */
export type Bbox = [number, number, number, number];

export async function points(params: { limit?: number; bbox?: Bbox; filter?: string } = {}) {
  const q = new URLSearchParams();
  if (params.limit != null) q.set('limit', String(params.limit));
  if (params.filter) q.set('filter', params.filter);
  if (params.bbox) q.set('bbox', params.bbox.join(','));
  const path = `/map/points${q.toString() ? `?${q.toString()}` : ''}`;
  return req(path, { auth: true });
}

export async function addPlace(body: {
  name: string;
  lat: number;
  lng: number;
  description?: string;
  photos?: string[];
  privacy?: 'all' | 'friends' | 'me';
}) {
  return req(`/points`, { method: 'POST', auth: true, body });
}

export async function placeById(id: number | string) {
  return req(`/points/${id}`, { auth: true });
}

/** ====== ADD CATCH ====== */
export async function addCatch(body: {
  lat: number;
  lng: number;
  species?: string;
  length?: number;
  weight?: number;
  style?: string;
  lure?: string;
  tackle?: string;
  notes?: string;
  photo_url?: string;
  caught_at?: string; // ISO 8601
  privacy?: 'all' | 'friends' | 'me';
}) {
  return req(`/catch`, { method: 'POST', auth: true, body });
}

/** ====== WEATHER FAVS ====== */
export async function getWeatherFavs() {
  return req(`/weather/favs`, { auth: true });
}

export async function saveWeatherFav(p: { lat: number; lng: number; name?: string }) {
  return req(`/weather/favs`, { method: 'POST', auth: true, body: p });
}

/** ====== PROFILE / NOTIFICATIONS ====== */
export async function profileMe() {
  return req(`/profile/me`, { auth: true });
}

export async function notifications() {
  return req(`/notifications`, { auth: true });
}

/** ====== AUTH ====== */
export async function authLogin(email: string, password: string) {
  const r = await req<{ token?: string; user?: any }>(`/auth/login`, {
    method: 'POST',
    body: { email, password },
  });
  if (r?.token) localStorage.setItem('token', r.token);
  return r;
}

export async function authRegister(payload: {
  email: string;
  password: string;
  name?: string;
  login?: string;
  agree_personal_data: boolean;
  agree_terms: boolean;
}) {
  const r = await req<{ token?: string; user?: any }>(`/auth/register`, {
    method: 'POST',
    body: payload,
  });
  if (r?.token) localStorage.setItem('token', r.token);
  return r;
}

export async function authLogout() {
  try { await req(`/auth/logout`, { method: 'POST', auth: true }); } catch {}
  localStorage.removeItem('token');
  return { ok: true };
}

/** ====== BANNERS (опционально, для централизованного вызова) ====== */
export async function bannersGet(slot: string, limit = 1) {
  const q = new URLSearchParams({ slot, limit: String(limit) });
  return req(`/banners?${q.toString()}`, { auth: false });
}

export default {
  // feed
  feed,
  catchById,
  addComment,
  likeCatch,
  rateCatch,
  bonusAward,
  addCatch,
  // map/points
  points,
  addPlace,
  placeById,
  // weather
  getWeatherFavs,
  saveWeatherFav,
  // profile / notifications
  profileMe,
  notifications,
  // auth
  authLogin,
  authRegister,
  authLogout,
  // banners
  bannersGet,
};
TS

echo "✅ Переписан $API_FILE"

echo "→ Быстрый аудит импортов из ./api.ts"
# Ищем все импорты из ./api или ../api, вытаскиваем имена
TMP_IMPORTS="$(mktemp)"
grep -RhoE "from ['\"](\.\.\/|\.)\/api['\"];?" frontend/src \
  | sed -n 'h;g;s/.*//;x;${x;p;}' >/dev/null 2>&1 || true

# Соберём именованные импорты
grep -RhoE "import\s+\{[^}]+\}\s+from\s+['\"](\.\.\/|\.)\/api['\"]" frontend/src \
  | sed -E 's/^import\s+\{([^}]+)\}.+/\1/' \
  | tr ',' '\n' | sed -E 's/^\s+|\s+$//g' \
  | sort -u > "$TMP_IMPORTS" || true

echo "Импортируемые имена:"
cat "$TMP_IMPORTS" || true
echo "—"

# Список экспортов из api.ts
TMP_EXPORTS="$(mktemp)"
grep -Eo "^export (async )?function [a-zA-Z0-9_]+" "$API_FILE" \
  | awk '{print $NF}' | sort -u > "$TMP_EXPORTS"

echo "Экспортируемые api-функции:"
cat "$TMP_EXPORTS"
echo "—"

# Дифф: что импортят, но нет в api.ts
echo "Проверка на несовпадения:"
comm -23 "$TMP_IMPORTS" "$TMP_EXPORTS" || true

echo "✅ Готово. Если список выше пуст — все импорты покрыты."
echo "Собери фронт: cd frontend && npm run build"