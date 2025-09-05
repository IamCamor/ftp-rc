export const CONFIG = {
  API_BASE: (import.meta.env.VITE_API_BASE as string) || 'https://api.fishtrackpro.ru/api/v1',
  CDN_BASE: (import.meta.env.VITE_CDN_BASE as string) || '',
  IMAGES: {
    logo: '/logo.svg',
    avatarDefault: '/default-avatar.png',
    bgPattern: '/bg-pattern.png',
  },
  Icons: {
    map: 'map',
    feed: 'dynamic_feed',
    alerts: 'notifications',
    profile: 'account_circle',
    plus: 'add',
    addCatch: 'fish',              // material symbol: "fish"
    addPlace: 'add_location_alt',
    like: 'favorite',
    comment: 'forum',
    share: 'ios_share',
    weather: 'sunny',
    wind: 'air',
    temp: 'device_thermostat',
    location: 'my_location',
    back: 'arrow_back',
    more: 'more_vert',
    bookmark: 'bookmark_add',
  } as const,
};
export type IconName = keyof typeof CONFIG.Icons;
