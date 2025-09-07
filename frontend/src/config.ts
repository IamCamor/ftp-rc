const config = {
  apiBase: (import.meta as any).env?.VITE_API_BASE ?? 'https://api.fishtrackpro.ru/api/v1',
  siteBase: (import.meta as any).env?.VITE_SITE_BASE ?? 'https://www.fishtrackpro.ru',
  assets: {
    logoUrl: '/logo.svg',
    defaultAvatar: '/default-avatar.png',
  },
  flags: {
    glass: true,
    // если на бэке нет ручек /api/v1/auth/login|register — выключаем password auth
    authPasswordEnabled: false,
    authOAuthEnabled: true,
    notificationsEnabled: false, // включите, когда появится /api/v1/notifications
    profileEnabled: false,        // включите, когда появится /api/v1/profile/me
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
