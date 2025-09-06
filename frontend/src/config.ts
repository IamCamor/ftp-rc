export const API_BASE = 'https://api.fishtrackpro.ru/api'; // без /v1 — добавим в api.ts
export const TILES_URL = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

export const ICONS = {
  // указываем имена иконок из Material Symbols Rounded
  header: { weather: 'weather_mix', bell: 'notifications', add: 'add_circle', profile: 'account_circle' },
  bottom: { feed: 'home', map: 'map', addCatch: 'add_photo_alternate', addPlace: 'add_location', alerts: 'notifications', profile: 'person' },
  actions: { like: 'favorite', comment: 'mode_comment', share: 'share', open: 'open_in_new', weatherSave: 'cloud_download' },
};

export const UI_DIMENSIONS = { header: 56, bottomNav: 64 };
