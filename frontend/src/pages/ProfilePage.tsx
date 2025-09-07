import React, { useEffect, useState } from 'react';
import config from '../config';
import { profileMe, isAuthed, logout } from '../api';
import { Link, useNavigate } from 'react-router-dom';
import Icon from '../components/Icon';

type Me = {
  id:number|string;
  name?:string;
  login?:string;
  avatar?:string;
  photoUrl?:string;
  rating?:number;
  email?:string;
};

export default function ProfilePage(){
  const [me, setMe] = useState<Me | null>(null);
  const [authed, setAuthed] = useState<boolean>(false);
  const navigate = useNavigate();

  useEffect(() => {
    (async () => {
      const ok = await isAuthed();
      setAuthed(!!ok);
      if (ok) {
        try { setMe(await profileMe()); } catch { setMe(null); }
      }
    })();
  }, []);

  const avatar = me?.photoUrl || me?.avatar || (config as any)?.assets?.defaultAvatar || '/assets/default-avatar.png';

  if (!authed){
    return (
      <div style={{padding:16}}>
        <div style={{
          backdropFilter:'blur(10px)',
          background:'rgba(255,255,255,0.35)',
          border:'1px solid rgba(255,255,255,0.4)',
          borderRadius:16, padding:16
        }}>
          <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:8}}>
            <Icon name="person" />
            <b>Профиль</b>
          </div>
          <div style={{marginBottom:12}}>Вы не авторизованы.</div>
          <div style={{display:'flex',gap:8}}>
            <Link to="/login" style={{padding:'8px 12px',borderRadius:10,background:'#0ea5e9',color:'#fff',textDecoration:'none'}}>Войти</Link>
            <Link to="/register" style={{padding:'8px 12px',borderRadius:10,background:'#111827',color:'#fff',textDecoration:'none'}}>Регистрация</Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div style={{padding:16, display:'grid', gap:12}}>
      <div style={{
        display:'flex', gap:12, alignItems:'center',
        backdropFilter:'blur(10px)',
        background:'rgba(255,255,255,0.35)',
        border:'1px solid rgba(255,255,255,0.4)',
        borderRadius:16, padding:16
      }}>
        <img src={avatar} alt="avatar" style={{width:64,height:64,borderRadius:'50%',objectFit:'cover'}} />
        <div>
          <div style={{fontWeight:700}}>{me?.name || me?.login || 'Пользователь'}</div>
          <div style={{fontSize:13,opacity:.8}}>{me?.email || ''}</div>
          {!!me?.rating && <div style={{fontSize:13,marginTop:4}}><Icon name="star" /> Рейтинг: {me.rating}</div>}
        </div>
      </div>

      <div style={{
        display:'flex', gap:8, flexWrap:'wrap'
      }}>
        <Link to="/profile/edit" style={{padding:'8px 12px',borderRadius:10,background:'#f3f4f6',textDecoration:'none'}}>Настройки профиля</Link>
        <Link to="/bonuses" style={{padding:'8px 12px',borderRadius:10,background:'#f3f4f6',textDecoration:'none'}}>Бонусы</Link>
        <Link to="/privacy" style={{padding:'8px 12px',borderRadius:10,background:'#f3f4f6',textDecoration:'none'}}>Конфиденциальность</Link>
      </div>

      <button
        onClick={async () => { try { await logout(); } catch {} navigate('/'); }}
        style={{padding:'10px 14px',borderRadius:12,background:'#ef4444',color:'#fff',border:0,cursor:'pointer',width:'fit-content'}}
      >
        Выйти
      </button>
    </div>
  );
}
