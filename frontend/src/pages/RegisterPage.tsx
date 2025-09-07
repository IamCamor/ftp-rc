import React, { useState } from 'react';
import config from '../config';
import AppShell from '../components/AppShell';
import Icon from '../components/Icon';
import { register } from '../api';

export default function RegisterPage(){
  const [email,setEmail] = useState('');
  const [login,setLogin] = useState('');
  const [password,setPassword] = useState('');
  const [agreePrivacy,setAgreePrivacy] = useState(false);
  const [agreeRules,setAgreeRules] = useState(false);
  const [msg,setMsg] = useState<string | null>(null);

  const can = config.flags.authPasswordEnabled;

  const submit = async (e:React.FormEvent)=>{
    e.preventDefault();
    setMsg(null);
    if (!agreePrivacy || !agreeRules) { setMsg('Нужно дать согласия'); return; }
    try{
      if (!can) throw new Error('Парольная регистрация отключена');
      await register({ email, password, login, agreePrivacy, agreeRules });
      setMsg('Регистрация успешна. Проверьте почту/вернитесь на вход.');
    }catch(err:any){
      setMsg(err?.message || 'Ошибка регистрации');
    }
  };

  return (
    <AppShell>
      <form onSubmit={submit} className="glass card" style={{maxWidth:560, margin:'12px auto', display:'grid', gap:12}}>
        <div className="row"><Icon name="person_add" /><b>Регистрация</b></div>

        <input placeholder="Логин" className="input" value={login} onChange={e=>setLogin(e.target.value)} />
        <input placeholder="Email" className="input" value={email} onChange={e=>setEmail(e.target.value)} />
        <input placeholder="Пароль" className="input" type="password" value={password} onChange={e=>setPassword(e.target.value)} />

        <label className="row" style={{gap:8}}>
          <input type="checkbox" checked={agreePrivacy} onChange={e=>setAgreePrivacy(e.target.checked)} />
          <span>Согласен на <a href={config.legal.privacyConsentUrl} target="_blank">обработку персональных данных</a></span>
        </label>
        <label className="row" style={{gap:8}}>
          <input type="checkbox" checked={agreeRules} onChange={e=>setAgreeRules(e.target.checked)} />
          <span>Согласен с <a href={config.legal.offerUrl} target="_blank">офертой</a> и <a href={config.legal.rulesUrl} target="_blank">правилами пользования</a></span>
        </label>

        {msg && <div className="help">{msg}</div>}

        <div className="row" style={{gap:8, flexWrap:'wrap'}}>
          <button className="btn primary" disabled={!can}><Icon name="check" /> Зарегистрироваться</button>
          <a className="btn ghost" href="/login"><Icon name="login" /> Уже есть аккаунт</a>
        </div>

        {!can && <div className="help">Парольная регистрация отключена — используйте вход через провайдеров на странице «Вход».</div>}
      </form>
    </AppShell>
  );
}
