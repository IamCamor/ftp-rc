/**
 * Централизованный конфиг:
 * - apiBase — обязательно с /api/v1
 * - assets — пути к логотипу/аватарке/фону
 * - icons — имена MUI-иконок (см. @mui/icons-material)
 * - pinTypes — карта типов точек к иконкам и стилям пинов
 */
export const CONFIG = {
  apiBase: "https://api.fishtrackpro.ru/api/v1",
  assets: {
    logo: "/assets/logo.png",
    avatar: "/assets/default-avatar.png",
    background: "/assets/pattern.png",
  },
  icons: {
    // глобальные
    feed: "Home",
    map: "Map",
    add: "AddCircle",
    alerts: "Notifications",
    profile: "Person",
    like: "FavoriteBorder",
    comment: "ChatBubbleOutline",
    share: "Share",
    weather: "WbSunny",
    back: "ArrowBack",
  },
  // Настройка пинов по типам
  pinTypes: {
    spot: {
      label: "Место",
      iconUrl: "/assets/pins/spot.svg",
      size: [28, 40],
      anchor: [14, 40],
      popupAnchor: [0, -36],
    },
    catch: {
      label: "Улов",
      iconUrl: "/assets/pins/catch.svg",
      size: [28, 40],
      anchor: [14, 40],
      popupAnchor: [0, -36],
    },
    shop: {
      label: "Магазин",
      iconUrl: "/assets/pins/shop.svg",
      size: [28, 40],
      anchor: [14, 40],
      popupAnchor: [0, -36],
    },
    base: {
      label: "База",
      iconUrl: "/assets/pins/base.svg",
      size: [28, 40],
      anchor: [14, 40],
      popupAnchor: [0, -36],
    },
    // fallback
    default: {
      label: "Точка",
      iconUrl: "/assets/pins/default.svg",
      size: [28, 40],
      anchor: [14, 40],
      popupAnchor: [0, -36],
    },
  } as Record<string, {
    label: string;
    iconUrl: string;
    size: [number, number];
    anchor: [number, number];
    popupAnchor: [number, number];
  }>,
} as const;
