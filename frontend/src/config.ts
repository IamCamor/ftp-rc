/**
 * Конфиг фронта.
 * apiBase можно переопределить через:
 *   1) window.__API_BASE__   (вставить <script>window.__API_BASE__="https://api.fishtrackpro.ru"</script>)
 *   2) VITE_API_BASE         (переменная окружения Vite)
 *   3) Значение по умолчанию ниже
 */
const config = {
  apiBase:
    (typeof window !== 'undefined' && (window as any).__API_BASE__) ||
    (import.meta as any).env?.VITE_API_BASE ||
    'https://api.fishtrackpro.ru',

  /** вкл/выкл расширенный лог сетевых попыток */
  debugNetwork: true,
} as const;

export default config;
