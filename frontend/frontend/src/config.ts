export type Providers = {
  google: boolean; vk: boolean; yandex: boolean; apple: boolean;
};

export type AppConfig = {
  apiBase: string;           // основной REST (/api/v1/*)
  authBase: string;          // базовый URL для /auth/* (без /api/v1)
  siteBase: string;
  images: {
    logoUrl: string;
    defaultAvatar: string;
    backgroundPattern: string;
  };
  icons: { [k: string]: string };
  banners: { feedEvery: number };
  auth: {
    enabled: boolean;
    providers: Providers;
    // пути на бэке, если отличаются — можно подменить
    routes: {
      login: string;            // POST
      register: string;         // POST
      oauthRedirect: (provider: keyof Providers) => string; // GET -> 302
    };
    // ссылки на документы
    links: {
      privacy: string;   // Перс. данные / Политика конф.
      offer: string;     // Публичная оферта
      terms: string;     // Правила пользования
    };
    // ограничения полей
    username: {
      min: number;
      max: number;
      pattern: RegExp;   // допустимые символы
    };
  };
};

const config: AppConfig = {
  apiBase: 'https://api.fishtrackpro.ru/api/v1',
  authBase: 'https://api.fishtrackpro.ru',
  siteBase: 'https://www.fishtrackpro.ru',
  images: {
    logoUrl: '/assets/logo.svg',
    defaultAvatar: '/assets/default-avatar.png',
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
    star: 'star',
    gift: 'redeem',
    friends: 'group',
    settings: 'settings',
    leaderboard: 'military_tech',
    ad: 'brand_awareness',
    google: 'google',
    vk: 'groups',
    yandex: 'language',
    apple: 'apple',
    edit: 'edit',
    image: 'image',
    save: 'save',
    login: 'login',
    logout: 'logout',
  },
  banners: { feedEvery: 5 },
  auth: {
    enabled: true,
    providers: { google: true, vk: true, yandex: true, apple: true },
    routes: {
      login: '/auth/login',
      register: '/auth/register',
      oauthRedirect: (p)=> `/auth/${p}/redirect`,
    },
    links: {
      privacy: 'https://www.fishtrackpro.ru/docs/privacy',
      offer:   'https://www.fishtrackpro.ru/docs/offer',
      terms:   'https://www.fishtrackpro.ru/docs/terms',
    },
    username: {
      min: 3,
      max: 24,
      pattern: /^[a-zA-Z0-9._-]+$/ as unknown as RegExp,
    }
  }
};

export default config;
