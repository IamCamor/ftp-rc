import React, { useState } from 'react';
import { login } from '../api';
import { useNavigate, Link } from 'react-router-dom';
import Icon from '../components/Icon';
import SocialAuth from '../components/SocialAuth';
import config from '../config';
import { pushToast } from '../components/Toast';

const LoginPage: React.FC = () => {
  const nav = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');

  async function onSubmit(e:React.FormEvent){
    e.preventDefault();
    setErr(''); setBusy(true);
    try{
      await login(email, password);
      pushToast('Добро пожаловать!');
      nav('/feed', { replace:true });
    }catch(e:any){
      setErr(e?.message || 'Не удалось войти');
    }finally{ setBusy(false); }
  }

  return (
    <div className="container" style={{maxWidth:560}}>
      <h2 className="h2">Вход</h2>
      <form onSubmit={onSubmit} className="glass card grid">
        <label>Email</label>
        <input className="input" type="email" required value={email} onChange={e=>setEmail(e.target.value)} />
        <label>Пароль</label>
        <input className="input" type="password" required value={password} onChange={e=>setPassword(e.target.value)} />
        {err && <div className="muted" style={{color:'#ffb4b4'}}>{err}</div>}
        <button className="btn primary" disabled={busy}><Icon name={config.icons.login}/> Войти</button>
      </form>

      <div className="glass card" style={{marginTop:12}}>
        <div style={{marginBottom:8, fontWeight:600}}>Быстрый вход</div>
        <SocialAuth/>
      </div>

      <div className="muted" style={{marginTop:12}}>
        Нет аккаунта? <Link to="/register">Зарегистрироваться</Link>
      </div>
    </div>
  );
};
export default LoginPage;
