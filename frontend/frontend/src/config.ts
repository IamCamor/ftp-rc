export type AppConfig = {
  apiBase: string;
  siteBase: string;
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
    star: string;
    gift: string;
    friends: string;
    settings: string;
    leaderboard: string;
    ad: string;
  };
  banners: {
    // через сколько элементов ленты вставлять баннер-слот
    feedEvery: number;
  }
};

const config: AppConfig = {
  apiBase: 'https://api.fishtrackpro.ru/api/v1',
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
  },
  banners: {
    feedEvery: 5
  }
};

export default config;
