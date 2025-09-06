#!/usr/bin/env bash
set -euo pipefail

FRONTEND_DIR="frontend"
SRC="$FRONTEND_DIR/src"

[ -d "$SRC" ] || { echo "❌ Не найден каталог $SRC"; exit 1; }

cat > "$SRC/config.ts" <<'TS'
/**
 * Глобальная конфигурация фронтенда.
 * Экспортируем и именованный `config`, и экспорт по умолчанию.
 */

export type AppConfig = {
  apiBase: string;
  cdnBase?: string;
  auth?: {
    enabled: boolean;
    tokenStorageKey: string;
  };
  routes: {
    feed: string;
    map: string;
    addCatch: string;
    addPlace: string;
    profile: string;
    alerts: string;
    weather: string;
    catchDetail: (id:number|string)=>string;
    placeDetail: (id:number|string)=>string;
  };
  icons: Record<string, string>;
  assets: {
    logo?: string;
    avatarDefault?: string;
    bgPattern?: string;
  };
  user?: {
    bonuses?: number;
  };
  map?: {
    defaultCenter: { lat: number; lng: number };
    defaultZoom: number;
  };
  features?: {
    aiModeration?: {
      enabled: boolean;
      provider?: 'openai'|'yandex'|'auto';
    };
  };
};

export const config: AppConfig = {
  apiBase: (window as any).__API_BASE__ ?? 'https://api.fishtrackpro.ru/api/v1',
  cdnBase: (window as any).__CDN_BASE__ ?? '',
  auth: {
    enabled: true,
    tokenStorageKey: 'ftp_token',
  },
  routes: {
    feed: '/feed',
    map: '/map',
    addCatch: '/catch/add',
    addPlace: '/place/add',
    profile: '/profile',
    alerts: '/alerts',
    weather: '/weather',
    catchDetail: (id) => `/catch/${id}`,
    placeDetail: (id) => `/place/${id}`,
  },
  // Материальные иконки — указываешь только имя glyph (text) из Material Symbols
  icons: {
    weather: 'cloud',
    notifications: 'notifications',
    bonus: 'military_tech',
    feed: 'dynamic_feed',
    map: 'map',
    addCatch: 'add_a_photo',
    addPlace: 'add_location_alt',
    profile: 'account_circle',
    like: 'favorite',
    comment: 'mode_comment',
    share: 'share',
    back: 'arrow_back',
    location: 'place',
    save: 'save',
    edit: 'edit',
  },
  // Пути картинок — можно вынести в CDN/Base
  assets: {
    logo: '/assets/logo.svg',
    avatarDefault: '/assets/default-avatar.png',
    bgPattern: '/assets/pattern.png',
  },
  user: {
    bonuses: 0,
  },
  map: {
    defaultCenter: { lat: 55.751244, lng: 37.618423 },
    defaultZoom: 9,
  },
  features: {
    aiModeration: {
      enabled: true,
      provider: 'auto',
    },
  },
};

// экспорт по умолчанию тоже оставляем, чтобы работать с `import config from './config'`
export default config;
TS

echo "✅ Пересобран $SRC/config.ts (named + default export)."

# Не падаем, если нет package.json — просто подсказка
if [ -f "$FRONTEND_DIR/package.json" ]; then
  echo "→ Пробуем билд фронта…"
  (cd "$FRONTEND_DIR" && npm run build) || {
    echo "⚠️ Билд вернул ошибку — посмотри лог выше. Но config.ts теперь правильный."
    exit 1
  }
fi

echo "🎉 Готово."