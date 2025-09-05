export const CONFIG = {
  apiBase: "https://api.fishtrackpro.ru/api/v1",
  siteBase: "https://www.fishtrackpro.ru",

  // Иконки (Material Icons) — можно менять названия тут и в коде просто писать name="..."
  icons: {
    logo: "Fishing",
    weather: "WbSunny",
    notifications: "Notifications",
    profile: "AccountCircle",
    map: "Map",
    feed: "DynamicFeed",
    alerts: "NotificationsActive",
    add: "Add",
    like: "FavoriteBorder",
    likeFilled: "Favorite",
    comment: "ChatBubbleOutline",
    share: "IosShare",
    place: "Place",
    back: "ArrowBack",
    edit: "Edit",
    logout: "Logout",
    friends: "Group",
    rating: "EmojiEvents",
    addPhoto: "AddPhotoAlternate",
    addLocation: "AddLocationAlt",
    save: "Save",
    delete: "Delete",
  } as Record<string,string>,

  // Пины на карте
  pinTypes: {
    spot:       { iconUrl: "/assets/pins/spot.svg", label: "Место", size:[28,40], anchor:[14,38], popupAnchor:[0,-32] },
    catch:      { iconUrl: "/assets/pins/catch.svg", label: "Улов", size:[28,40], anchor:[14,38], popupAnchor:[0,-32] },
    shop:       { iconUrl: "/assets/pins/shop.svg", label: "Магазин", size:[28,40], anchor:[14,38], popupAnchor:[0,-32] },
    base:       { iconUrl: "/assets/pins/base.svg", label: "База", size:[28,40], anchor:[14,38], popupAnchor:[0,-32] },
    default:    { iconUrl: "/assets/pins/default.svg", label: "Точка", size:[28,40], anchor:[14,38], popupAnchor:[0,-32] },
  } as any,

  // Графика
  images: {
    logo: "/assets/logo.png",
    avatarDefault: "/assets/default-avatar.png",
    pattern: "/assets/pattern.png"
  },

  // Шапка/навигация
  nav: {
    topLinks: {
      weather: "/weather",
      notifications: "/alerts",
      profile: "/profile",
      map: "/map",
      feed: "/feed",
    },
    bottomTabs: [
      { key: "map",  path: "/map",  label: "Карта", icon: "map" },
      { key: "feed", path: "/feed", label: "Лента", icon: "feed" },
      { key: "alerts", path: "/alerts", label: "Увед.", icon: "alerts" },
      { key: "profile", path: "/profile", label: "Профиль", icon: "profile" },
    ]
  }
};
