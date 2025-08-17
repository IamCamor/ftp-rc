import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

// Languages list
export const SUPPORTED_LANGS = [
  'en','ru','es','de','fr','it','pt','tr','pl','uk','zh','ja','ko','ar','hi'
] as const;
export type Lang = typeof SUPPORTED_LANGS[number];

// detect language from localStorage or browser
const defaultLang = (localStorage.getItem('lang') || import.meta.env.VITE_DEFAULT_LANG || 'en') as Lang;

const resources = Object.fromEntries(
  SUPPORTED_LANGS.map((lng) => [lng, { translation: {} }])
);

// We'll lazy load JSON per language via dynamic import
async function loadLang(lang: Lang) {
  const mod = await import(`./locales/${lang}.json`);
  i18n.addResources(lang, 'translation', mod.default);
}

i18n
  .use(initReactI18next)
  .init({
    resources,
    lng: defaultLang,
    fallbackLng: 'en',
    interpolation: { escapeValue: false },
  });

// preload current lang
loadLang(defaultLang);

export async function setLang(lang: Lang) {
  if (!SUPPORTED_LANGS.includes(lang)) return;
  await loadLang(lang);
  await i18n.changeLanguage(lang);
  localStorage.setItem('lang', lang);
}

export default i18n;
