type IconsConfig = {
  // имена для Material Symbols Rounded
  logo?: string;
  weather?: string;
  bell?: string;
  add?: string;
  map?: string;
  feed?: string;
  profile?: string;
  like?: string;
  comment?: string;
  share?: string;
};

type FeatureFlags = {
  auth: {
    local: boolean;
    oauthGoogle: boolean;
    oauthVk: boolean;
    oauthYandex: boolean;
    oauthApple: boolean;
    requireAgreementOnSignup: boolean;
  };
  ui: {
    glass: boolean;
    showWeatherLinkInHeader: boolean;
  };
  weather: {
    allowSavePoint: boolean;
    requireAuthForWeatherSave: boolean;
  };
};

export type AppConfig = {
  appName: string;
  apiBase: string;   // e.g. https://api.fishtrackpro.ru/api/v1
  authBase: string;  // e.g. https://api.fishtrackpro.ru
  legal: {
    termsUrl: string;
    privacyUrl: string;
    offerUrl: string;
  };
  assets: {
    logoUrl: string;
    defaultAvatar: string;
    bgPattern?: string;
  };
  icons: IconsConfig;
  features: FeatureFlags;
};

// ❗ Отредактируйте при необходимости URL-ы для прод/стейдж:
const config: AppConfig = {
  appName: "FishTrack Pro",
  apiBase: (typeof window !== 'undefined'
    ? (window as any).__API_BASE__
    : "") || "https://api.fishtrackpro.ru/api/v1",
  authBase: (typeof window !== 'undefined'
    ? (window as any).__AUTH_BASE__
    : "") || "https://api.fishtrackpro.ru",

  legal: {
    termsUrl: "https://www.fishtrackpro.ru/legal/terms",
    privacyUrl: "https://www.fishtrackpro.ru/legal/privacy",
    offerUrl: "https://www.fishtrackpro.ru/legal/offer",
  },

  assets: {
    logoUrl: "/static/logo.svg",
    defaultAvatar: "/static/default-avatar.png",
    bgPattern: "/static/pattern.png",
  },

  icons: {
    logo: "waves",
    weather: "partly_cloudy_day",
    bell: "notifications",
    add: "add",
    map: "map",
    feed: "dynamic_feed",
    profile: "account_circle",
    like: "favorite",
    comment: "chat",
    share: "share",
  },

  features: {
    auth: {
      local: true,
      oauthGoogle: true,
      oauthVk: true,
      oauthYandex: true,
      oauthApple: true,
      requireAgreementOnSignup: true,
    },
    ui: {
      glass: true,
      showWeatherLinkInHeader: true,
    },
    weather: {
      allowSavePoint: true,
      requireAuthForWeatherSave: true,
    },
  },
};

export default config;
