import React from 'react';
import { login, oauthStart } from '../api';
import config from '../config';

const AuthLoginPage: React.FC = ()=>{
  const [email,setEmail] = React.useState('');
  const [password,setPassword] = React.useState('');
  const [error,setError] = React.useState<string|undefined>();

  async function onSubmit(e:React.FormEvent){
    e.preventDefault();
    setError(undefined);
    try{
      await login(email, password);
      window.location.href = '/';
    }catch(err:any){
      setError(err?.message || 'Ошибка входа');
    }
  }

  const p = config.auth.providers;

  return (
    <div className="container" style={{maxWidth:420}}>
      <h2>Вход</h2>
      {error && <div className="glass card" style={{color:'crimson'}}>{error}</div>}
      <form onSubmit={onSubmit} className="glass card" style={{display:'grid', gap:12}}>
        <input placeholder="Email" type="email" value={email} onChange={e=>setEmail(e.target.value)} required />
        <input placeholder="Пароль" type="password" value={password} onChange={e=>setPassword(e.target.value)} required />
        <button className="btn primary" type="submit">Войти</button>
      </form>

      <div className="glass card" style={{marginTop:12}}>
        <div style={{display:'grid', gap:8}}>
          {p.google && <button className="btn" onClick={()=>oauthStart('google')}>Войти через Google</button>}
          {p.vk     && <button className="btn" onClick={()=>oauthStart('vk')}>Войти через VK</button>}
          {p.yandex && <button className="btn" onClick={()=>oauthStart('yandex')}>Войти через Яндекс</button>}
          {p.apple  && <button className="btn" onClick={()=>oauthStart('apple')}>Войти через Apple</button>}
        </div>
      </div>

      <div style={{marginTop:12}}>
        Нет аккаунта? <a href="/register">Зарегистрироваться</a>
      </div>
    </div>
  );
};
export default AuthLoginPage;
