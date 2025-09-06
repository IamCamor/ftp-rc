/**
 * Единый конфиг приложения.
 * ВАЖНО: default export!
 */
export type AppConfig = {
  apiBase: string;
  debugNetwork: boolean;
  ui: {
    logoUrl: string;
    defaultAvatar: string;
    bgPattern: string;
    icons: Record<string, string>;
  };
};

const API_FROM_WINDOW =
  (typeof window !== 'undefined' && (window as any).__API_BASE__) || '';

const config: AppConfig = {
  apiBase: API_FROM_WINDOW || 'https://api.fishtrackpro.ru',
  debugNetwork: false,
  ui: {
    // поставьте сюда ваш лого, можно абсолютный https://
    logoUrl: '/logo.svg',
    // дефолтная аватарка (желательно https, чтобы не ловить mixed content/cert)
    defaultAvatar: 'https://www.fishtrackpro.ru/assets/default-avatar.png',
    // фоновый паттерн
    bgPattern: 'https://www.fishtrackpro.ru/assets/pattern.png',
    // материал-иконки по ключам
    icons: {
      feed: 'home',
      map: 'map',
      add: 'add_circle',
      alerts: 'notifications',
      profile: 'account_circle',
      like: 'favorite',
      comment: 'chat_bubble',
      share: 'share',
      weather: 'cloud',
      back: 'arrow_back',
    },
  },
};

export default config;
