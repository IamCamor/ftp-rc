import React from 'react';
import config from '../config';
import AppShell from '../components/AppShell';
import Icon from '../components/Icon';

export default function LoginPage(){
  const oauth = config.flags.authOAuthEnabled;
  const pwd   = config.flags.authPasswordEnabled;

  const go = (path: string) => {
    const base = config.siteBase.replace(/\/+$/,'');
    const api = config.apiBase.replace(/\/api\/v1$/,''); // перейти на корень api-домена
    window.location.href = `${api}${path}`;
  };

  return (
    <AppShell>
      <div className="glass card" style={{maxWidth:520, margin:'12px auto', display:'grid', gap:12}}>
        <div className="row"><Icon name="login" /><b>Вход в аккаунт</b></div>
        {oauth && (
          <div style={{display:'grid',gap:8}}>
            {config.providers.google.enabled && (
              <button className="btn ghost" onClick={()=>go(config.providers.google.path)}><Icon name="google" /> Войти через Google</button>
            )}
            {config.providers.vk.enabled && (
              <button className="btn ghost" onClick={()=>go(config.providers.vk.path)}><Icon name="language" /> Войти через VK</button>
            )}
            {config.providers.yandex.enabled && (
              <button className="btn ghost" onClick={()=>go(config.providers.yandex.path)}><Icon name="travel_explore" /> Войти через Яндекс</button>
            )}
            {config.providers.apple.enabled && (
              <button className="btn ghost" onClick={()=>go(config.providers.apple.path)}><Icon name="apple" /> Войти через Apple</button>
            )}
          </div>
        )}

        {!oauth && !pwd && (
          <div className="help">Авторизация временно недоступна (отключена флагами).</div>
        )}

        <div className="sep" />
        <a href="/register" className="btn primary"><Icon name="how_to_reg" /> Регистрация</a>
      </div>
    </AppShell>
  );
}
