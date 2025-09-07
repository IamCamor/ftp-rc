import React, { useState } from 'react';
import { login } from '../api';
import { useNavigate, Link } from 'react-router-dom';

const LoginPage: React.FC = () => {
  const nav = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPwd] = useState('');
  const [err, setErr] = useState('');

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr('');
    try {
      await login(email, password);
      nav('/profile', { replace: true });
    } catch (ex:any) {
      setErr(ex?.message || 'Ошибка входа');
    }
  }

  return (
    <div className="container">
      <form className="glass card" onSubmit={onSubmit} style={{display:'grid', gap:10, maxWidth:420, margin:'0 auto'}}>
        <h2>Вход</h2>
        <label>Email</label>
        <input className="input" value={email} onChange={e=>setEmail(e.target.value)} required />
        <label>Пароль</label>
        <input className="input" type="password" value={password} onChange={e=>setPwd(e.target.value)} required />
        <button className="btn primary" type="submit">Войти</button>
        {err && <div style={{color:'#ffb4b4'}}>{err}</div>}
        <div className="muted">Нет аккаунта? <Link to="/register">Регистрация</Link></div>
      </form>
    </div>
  );
};

export default LoginPage;
