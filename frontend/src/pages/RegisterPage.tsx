import React, { useState } from 'react';
import { register } from '../api';
import { useNavigate, Link } from 'react-router-dom';

const RegisterPage: React.FC = () => {
  const nav = useNavigate();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPwd] = useState('');
  const [err, setErr] = useState('');

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr('');
    try {
      await register(name, email, password);
      nav('/profile', { replace: true });
    } catch (ex:any) {
      setErr(ex?.message || 'Ошибка регистрации');
    }
  }

  return (
    <div className="container">
      <form className="glass card" onSubmit={onSubmit} style={{display:'grid', gap:10, maxWidth:420, margin:'0 auto'}}>
        <h2>Регистрация</h2>
        <label>Имя</label>
        <input className="input" value={name} onChange={e=>setName(e.target.value)} required />
        <label>Email</label>
        <input className="input" value={email} onChange={e=>setEmail(e.target.value)} required />
        <label>Пароль</label>
        <input className="input" type="password" value={password} onChange={e=>setPwd(e.target.value)} required />
        <button className="btn primary" type="submit">Создать аккаунт</button>
        {err && <div style={{color:'#ffb4b4'}}>{err}</div>}
        <div className="muted">Уже есть аккаунт? <Link to="/login">Вход</Link></div>
      </form>
    </div>
  );
};

export default RegisterPage;
