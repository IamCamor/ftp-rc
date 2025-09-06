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
