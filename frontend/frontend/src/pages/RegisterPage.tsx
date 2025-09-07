import React, { useMemo, useState } from 'react';
import { register, updateAvatar, updateUsername } from '../api';
import { useNavigate, Link } from 'react-router-dom';
import Icon from '../components/Icon';
import SocialAuth from '../components/SocialAuth';
import config from '../config';
import { pushToast } from '../components/Toast';

const re = config.auth.username.pattern as unknown as RegExp;

const RegisterPage: React.FC = () => {
  const nav = useNavigate();
  const [name, setName] = useState('');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [avatarUrl, setAvatarUrl] = useState('');
  const [agreePrivacy, setAgreePrivacy] = useState(false);
  const [agreeOffer, setAgreeOffer] = useState(false);
  const [agreeTerms, setAgreeTerms] = useState(false);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');

  const usernameOk = useMemo(()=>{
    if (username.length < config.auth.username.min) return false;
    if (username.length > config.auth.username.max) return false;
    return re.test(username);
  },[username]);

  async function onSubmit(e:React.FormEvent){
    e.preventDefault();
    setErr('');
    if (!agreePrivacy || !agreeOffer || !agreeTerms) {
      setErr('Необходимо согласиться с документами.');
      return;
    }
    if (!usernameOk) {
      setErr('Некорректный логин. Разрешены латиница/цифры/._-');
      return;
    }
    setBusy(true);
    try{
      await register(name, email, password, username, avatarUrl || undefined);
      // дополнительно пробуем через settings, если бэк не принял в /auth/register
      if (username) await updateUsername(username).catch(()=>{});
      if (avatarUrl) await updateAvatar(avatarUrl).catch(()=>{});
      pushToast('Регистрация успешна');
      nav('/feed', { replace:true });
    }catch(e:any){
      setErr(e?.message || 'Не удалось зарегистрироваться');
    }finally{ setBusy(false); }
  }

  return (
    <div className="container" style={{maxWidth:720}}>
      <h2 className="h2">Регистрация</h2>
      <form onSubmit={onSubmit} className="glass card grid">
        <div className="grid" style={{gridTemplateColumns:'1fr 1fr', gap:12}}>
          <div>
            <label>Имя</label>
            <input className="input" required value={name} onChange={e=>setName(e.target.value)} />
          </div>
          <div>
            <label>Логин</label>
            <input className="input" required value={username} onChange={e=>setUsername(e.target.value)} placeholder="a-z 0-9 . _ -" />
            <small className="muted">
              {config.auth.username.min}–{config.auth.username.max} символов
            </small>
          </div>
          <div>
            <label>Email</label>
            <input className="input" type="email" required value={email} onChange={e=>setEmail(e.target.value)} />
          </div>
          <div>
            <label>Пароль</label>
            <input className="input" type="password" required value={password} onChange={e=>setPassword(e.target.value)} />
          </div>
          <div style={{gridColumn:'1 / span 2'}}>
            <label><Icon name={config.icons.image}/> URL аватарки (по желанию)</label>
            <input className="input" type="url" placeholder="https://..." value={avatarUrl} onChange={e=>setAvatarUrl(e.target.value)} />
          </div>
        </div>

        <div className="grid" style={{gap:8, marginTop:8}}>
          <label className="row">
            <input type="checkbox" checked={agreePrivacy} onChange={e=>setAgreePrivacy(e.target.checked)} />
            <span>Согласие на обработку персональных данных (<a href={config.auth.links.privacy} target="_blank">политика</a>)</span>
          </label>
          <label className="row">
            <input type="checkbox" checked={agreeOffer} onChange={e=>setAgreeOffer(e.target.checked)} />
            <span>Согласие с <a href={config.auth.links.offer} target="_blank">офертой</a></span>
          </label>
          <label className="row">
            <input type="checkbox" checked={agreeTerms} onChange={e=>setAgreeTerms(e.target.checked)} />
            <span>Согласие с <a href={config.auth.links.terms} target="_blank">правилами пользования</a></span>
          </label>
        </div>

        {err && <div className="muted" style={{color:'#ffb4b4'}}>{err}</div>}
        <button className="btn primary" disabled={busy}><Icon name={config.icons.save}/> Создать аккаунт</button>
      </form>

      <div className="glass card" style={{marginTop:12}}>
        <div style={{marginBottom:8, fontWeight:600}}>Или зарегистрируйтесь через соцсети</div>
        <SocialAuth/>
      </div>

      <div className="muted" style={{marginTop:12}}>
        Уже с нами? <Link to="/login">Войти</Link>
      </div>
    </div>
  );
};
export default RegisterPage;
