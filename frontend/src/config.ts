const config = {
  apiBase: (import.meta as any).env?.VITE_API_BASE || 'https://api.fishtrackpro.ru',
  brand: {
    name: 'FishTrack Pro',
    // укажи ссылки на свои ассеты (https, валидные сертификаты)
    logoUrl: '/logo.svg',
    defaultAvatar: '/default-avatar.png',
    bgPattern: '/bg-pattern.png',
  }
};
export default config;
