#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
SRC="${ROOT}/src"

if [ ! -d "$SRC" ]; then
  # если запущено из корня репо вида frontend/, попробуем поправить путь
  if [ -d "${ROOT}/frontend/src" ]; then
    SRC="${ROOT}/frontend/src"
  else
    echo "❌ Не найдена папка src. Запускайте из корня фронтенда или репозитория."
    exit 1
  fi
fi

echo "→ Пишу ${SRC}/config.ts"
cat > "${SRC}/config.ts" <<'TS'
/**
 * Единый конфиг приложения.
 * ВАЖНО: default export!
 */
export type AppConfig = {
  apiBase: string;
  debugNetwork: boolean;
  ui: {
    logoUrl: string;
    defaultAvatar: string;
    bgPattern: string;
    icons: Record<string, string>;
  };
};

const API_FROM_WINDOW =
  (typeof window !== 'undefined' && (window as any).__API_BASE__) || '';

const config: AppConfig = {
  apiBase: API_FROM_WINDOW || 'https://api.fishtrackpro.ru',
  debugNetwork: false,
  ui: {
    // поставьте сюда ваш лого, можно абсолютный https://
    logoUrl: '/logo.svg',
    // дефолтная аватарка (желательно https, чтобы не ловить mixed content/cert)
    defaultAvatar: 'https://www.fishtrackpro.ru/assets/default-avatar.png',
    // фоновый паттерн
    bgPattern: 'https://www.fishtrackpro.ru/assets/pattern.png',
    // материал-иконки по ключам
    icons: {
      feed: 'home',
      map: 'map',
      add: 'add_circle',
      alerts: 'notifications',
      profile: 'account_circle',
      like: 'favorite',
      comment: 'chat_bubble',
      share: 'share',
      weather: 'cloud',
      back: 'arrow_back',
    },
  },
};

export default config;
TS

echo "→ Пишу ${SRC}/components/Header.tsx"
mkdir -p "${SRC}/components"
cat > "${SRC}/components/Header.tsx" <<'TS'
import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import config from '../config';
import Icon from './Icon';

type HeaderProps = {
  bonuses?: number;
};

const Header: React.FC<HeaderProps> = ({ bonuses = 0 }) => {
  const { pathname } = useLocation();
  const ui = config?.ui || ({} as any);
  const logo = ui.logoUrl || '';
  const bg = ui.bgPattern || '';

  return (
    <header
      className="app-header glass"
      style={{
        position: 'sticky',
        top: 0,
        backdropFilter: 'blur(10px)',
        WebkitBackdropFilter: 'blur(10px)',
        background:
          'linear-gradient(135deg, rgba(255,255,255,0.55), rgba(255,255,255,0.15))',
        borderBottom: '1px solid rgba(255,255,255,0.2)',
        zIndex: 10,
      }}
    >
      <div
        style={{
          backgroundImage: bg ? `url(${bg})` : 'none',
          backgroundSize: 'cover',
          backgroundRepeat: 'no-repeat',
        }}
      >
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: '1fr auto 1fr',
            alignItems: 'center',
            gap: '12px',
            padding: '10px 12px',
          }}
        >
          <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
            <Link to="/" title="Лента">
              {logo ? (
                <img
                  src={logo}
                  alt="logo"
                  style={{ height: 28, width: 'auto', display: 'block' }}
                />
              ) : (
                <strong>FishTrack Pro</strong>
              )}
            </Link>
          </div>

          <div style={{ textAlign: 'center', fontWeight: 600 }}>
            {pathname === '/map'
              ? 'Карта'
              : pathname === '/alerts'
              ? 'Уведомления'
              : pathname === '/profile'
              ? 'Профиль'
              : pathname === '/weather'
              ? 'Погода'
              : 'Лента'}
          </div>

          <div
            style={{
              display: 'flex',
              gap: 14,
              alignItems: 'center',
              justifyContent: 'flex-end',
            }}
          >
            <Link to="/weather" aria-label="Погода" title="Погода">
              <Icon name={ui.icons?.weather || 'cloud'} size={24} />
            </Link>

            <Link to="/alerts" aria-label="Уведомления" title="Уведомления">
              <Icon name={ui.icons?.alerts || 'notifications'} size={24} />
            </Link>

            <Link to="/profile" aria-label="Профиль" title="Профиль">
              <div
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 6,
                  padding: '4px 8px',
                  borderRadius: 999,
                  background: 'rgba(0,0,0,0.05)',
                }}
              >
                <Icon name={ui.icons?.profile || 'account_circle'} size={22} />
                <span style={{ fontSize: 12, fontWeight: 700 }}>{bonuses}</span>
              </div>
            </Link>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;
TS

# На всякий случай правим BottomNav на default-import config
if [ -f "${SRC}/components/BottomNav.tsx" ]; then
  echo "→ Обновляю ${SRC}/components/BottomNav.tsx (импорт config)"
  perl -0777 -pe 's/import\s*\{\s*config\s*\}\s*from\s*[\'"]\.\.\/config[\'"]/import config from "..\/config"/g' \
    -i "${SRC}/components/BottomNav.tsx" || true
fi

echo "✅ Готово. Теперь соберите проект: npm run build"