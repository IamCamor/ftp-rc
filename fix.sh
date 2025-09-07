#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"

cat > "$ROOT/frontend/src/config.ts" <<'TS'
/**
 * Глобальная конфигурация фронтенда.
 * ВАЖНО: экспорт по умолчанию (default), чтобы импорты `import config from '../config'` работали.
 */
type AuthProviders = {
  passwordForm: boolean;
  google: boolean;
  vk: boolean;
  yandex: boolean;
  apple: boolean;
};

type FeatureFlags = {
  auth: {
    enabled: boolean;
    providers: AuthProviders;
    // Требовать авторизацию для сохранения точки погоды/локаций:
    requireAuthForWeatherSave: boolean;
    // Ссылки на документы (оферта/ПДн/правила)
    links: {
      offer: string;
      personalData: string;
      rules: string;
    };
  };
  banners: boolean;
  ratings: boolean;
  bonusProgram: boolean;
  glassUi: boolean;
};

const config = {
  // Базы
  apiBase: 'https://api.fishtrackpro.ru/api/v1',
  siteBase: 'https://www.fishtrackpro.ru',
  assetsBase: 'https://www.fishtrackpro.ru/assets',

  // Брендинг/ресурсы
  logoUrl: '/logo.svg',
  defaultAvatar: '/default-avatar.png',

  // Параметры UI
  glassEnabled: true, // включает эффекты glassmorphism
  feedEvery: 60000,   // период авто-обновления ленты в мс (60 сек)

  // Карта
  map: {
    defaultCenter: { lat: 55.751244, lng: 37.618423 }, // Москва по умолчанию
    defaultZoom: 10,
    tiles: {
      url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution:
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    },
    // максимальное кол-во точек за раз
    maxPoints: 1000,
  },

  // Фичи и фича-флаги
  features: {
    auth: {
      enabled: true,
      providers: {
        passwordForm: true, // включить форму email+password
        google: true,
        vk: true,
        yandex: true,
        apple: true,
      } as AuthProviders,
      requireAuthForWeatherSave: true,
      links: {
        offer: 'https://www.fishtrackpro.ru/docs/offer',
        personalData: 'https://www.fishtrackpro.ru/docs/personal-data',
        rules: 'https://www.fishtrackpro.ru/docs/rules',
      },
    },
    banners: true,
    ratings: true,
    bonusProgram: true,
    glassUi: true,
  } as FeatureFlags,

  // Роуты (на будущее; может использоваться в лэйауте/навигации)
  routes: {
    feed: '/feed',
    map: '/map',
    addCatch: '/add/catch',
    addPlace: '/add/place',
    alerts: '/alerts',
    profile: '/profile',
    weather: '/weather',
    catchDetail: (id: number|string) => `/catch/${id}`,
    placeDetail: (id: number|string) => `/place/${id}`,
    auth: {
      login: '/auth/login',
      register: '/auth/register',
    },
  },
};

export type AppConfig = typeof config;
export default config;
TS

echo "✅ config.ts обновлён.
Дальше:
  cd frontend
  npm run build
  npm run preview
"