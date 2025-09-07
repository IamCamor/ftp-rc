const config = {
  apiBase: (import.meta as any).env?.VITE_API_BASE ?? 'https://api.fishtrackpro.ru/api/v1',
  siteBase: (import.meta as any).env?.VITE_SITE_BASE ?? 'https://www.fishtrackpro.ru',
  assets: {
    logoUrl: '/logo.svg',
    defaultAvatar: '/default-avatar.png',
  },
  ui: {
    // период авто-обновления ленты в мс (можно отключить = 0)
    feedEvery: 60000,
  },
  flags: {
    glass: true,
    authPasswordEnabled: false,
    authOAuthEnabled: true,
    notificationsEnabled: false,
    profileEnabled: false,
    requireAuthForWeatherSave: false,
  },
  legal: {
    privacyConsentUrl: '/legal/privacy',
    offerUrl: '/legal/offer',
    rulesUrl: '/legal/rules',
  },
  providers: {
    google:  { enabled: true,  path: '/auth/google/redirect' },
    vk:      { enabled: true,  path: '/auth/vk/redirect' },
    yandex:  { enabled: true,  path: '/auth/yandex/redirect' },
    apple:   { enabled: true,  path: '/auth/apple/redirect' },
  },
  banners: {
    enabled: true,
    slots: ['feed.top','feed.bottom','map.bottom'],
  },
};
export default config;
