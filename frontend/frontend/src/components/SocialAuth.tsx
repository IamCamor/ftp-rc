import React from 'react';
import config from '../config';
import Icon from './Icon';
import { oauthStart } from '../api';

const ProviderBtn: React.FC<{p:'google'|'vk'|'yandex'|'apple'; label:string}> = ({p,label}) => (
  <button type="button" className="btn" onClick={()=>oauthStart(p)} aria-label={label} title={label}>
    <Icon name={config.icons[p]} /> <span className="hide-sm">{label}</span>
  </button>
);

const SocialAuth: React.FC = () => {
  if (!config.auth.enabled) return null;
  const { providers } = config.auth;
  return (
    <div className="row" style={{gap:8, flexWrap:'wrap'}}>
      {providers.google && <ProviderBtn p="google" label="Войти через Google" />}
      {providers.vk && <ProviderBtn p="vk" label="Войти через VK" />}
      {providers.yandex && <ProviderBtn p="yandex" label="Войти через Yandex" />}
      {providers.apple && <ProviderBtn p="apple" label="Войти через Apple" />}
    </div>
  );
};

export default SocialAuth;
