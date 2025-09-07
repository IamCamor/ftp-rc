import React from 'react';
import { register, oauthStart } from '../api';
import config from '../config';
import LegalCheckboxes from '../components/LegalCheckboxes';

const AuthRegisterPage: React.FC = ()=>{
  const [name,setName] = React.useState('');
  const [username,setUsername] = React.useState('');
  const [email,setEmail] = React.useState('');
  const [password,setPassword] = React.useState('');
  const [agree,setAgree] = React.useState({privacy:false, offer:false, terms:false});
  const [error,setError] = React.useState<string|undefined>();

  const usernameCfg = config.auth.username;

  async function onSubmit(e:React.FormEvent){
    e.preventDefault();
    setError(undefined);
    if(!(agree.privacy && agree.offer && agree.terms)){
      setError('Необходимо принять все согласия.');
      return;
    }
    if(username && (username.length < usernameCfg.min || username.length > usernameCfg.max)){
      setError(`Логин от ${usernameCfg.min} до ${usernameCfg.max} символов`);
      return;
    }
    try{
      await register(name, email, password, username);
      window.location.href = '/';
    }catch(err:any){
      setError(err?.message || 'Ошибка регистрации');
    }
  }

  const p = config.auth.providers;

  return (
    <div className="container" style={{maxWidth:480}}>
      <h2>Регистрация</h2>
      {error && <div className="glass card" style={{color:'crimson'}}>{error}</div>}
      <form onSubmit={onSubmit} className="glass card" style={{display:'grid', gap:12}}>
        <input placeholder="Имя" value={name} onChange={e=>setName(e.target.value)} required />
        <input placeholder="Логин (a-z, 0-9, . _ -)" value={username} onChange={e=>setUsername(e.target.value)} />
        <input placeholder="Email" type="email" value={email} onChange={e=>setEmail(e.target.value)} required />
        <input placeholder="Пароль" type="password" value={password} onChange={e=>setPassword(e.target.value)} required />

        <LegalCheckboxes
          checkedPrivacy={agree.privacy}
          checkedOffer={agree.offer}
          checkedTerms={agree.terms}
          onChange={(p)=> setAgree(prev=>({...prev, ...p}))}
        />

        <button className="btn primary" type="submit">Зарегистрироваться</button>
      </form>

      <div className="glass card" style={{marginTop:12}}>
        <div style={{display:'grid', gap:8}}>
          {p.google && <button className="btn" onClick={()=>oauthStart('google')}>Через Google</button>}
          {p.vk     && <button className="btn" onClick={()=>oauthStart('vk')}>Через VK</button>}
          {p.yandex && <button className="btn" onClick={()=>oauthStart('yandex')}>Через Яндекс</button>}
          {p.apple  && <button className="btn" onClick={()=>oauthStart('apple')}>Через Apple</button>}
        </div>
      </div>

      <div style={{marginTop:12}}>
        Уже есть аккаунт? <a href="/login">Войти</a>
      </div>
    </div>
  );
};
export default AuthRegisterPage;
