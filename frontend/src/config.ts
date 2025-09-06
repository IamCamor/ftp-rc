export type AppConfig = {
  apiBase: string;
  assets: {
    logo: string;
    defaultAvatar: string;
    bgPattern?: string;
  };
  icons?: Record<string,string>;
};

export const config: AppConfig = {
  apiBase: 'https://api.fishtrackpro.ru/api/v1',
  assets: {
    logo: '/logo.svg',
    defaultAvatar: '/default-avatar.png',
    bgPattern: '/bg-pattern.png',
  },
  icons: {
    feed: 'home',
    map: 'map',
    add: 'add_circle',
    alerts: 'notifications',
    profile: 'person',
    weather: 'cloud',
    like: 'favorite',
    comment: 'chat_bubble',
    share: 'ios_share',
    back: 'arrow_back',
  }
};

export default config;
