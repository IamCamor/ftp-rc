export type AppConfig = {
  apiBase: string;        // База API (по ТЗ: /api/v1)
  siteBase: string;       // База сайта (для ссылок)
  images: {
    logoUrl: string;
    defaultAvatar: string;
    backgroundPattern: string;
  };
  icons: {
    like: string;
    comment: string;
    share: string;
    map: string;
    add: string;
    alerts: string;
    profile: string;
    weather: string;
    home: string;
  };
};

const config: AppConfig = {
  apiBase: 'https://api.fishtrackpro.ru/api/v1',
  authBase: 'https://api.fishtrackpro.ru',
  siteBase: 'https://www.fishtrackpro.ru',
  images: {
    logoUrl: '/assets/logo.svg',
    defaultAvatar: '/assets/default-avatar.png', // Подложка; если нет — отменится на /src/assets
    backgroundPattern: '/assets/bg-pattern.png',
  },
  icons: {
    like: 'favorite',
    comment: 'chat_bubble',
    share: 'share',
    map: 'map',
    add: 'add_location_alt',
    alerts: 'notifications',
    profile: 'account_circle',
    weather: 'partly_cloudy_day',
    home: 'home',
  },
};

export default config;
