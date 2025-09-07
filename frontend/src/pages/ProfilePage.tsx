import React, { useEffect, useState } from 'react';
import AppShell from '../components/AppShell';
import Icon from '../components/Icon';
import config from '../config';
import { profileMe, isAuthed, logout } from '../api';

export default function ProfilePage(){
  const [me,setMe] = useState<any>(null);
  const [ready,setReady] = useState(false);

  useEffect(()=>{
    let canceled=false;
    (async()=>{
      if (!isAuthed() || !config.flags.profileEnabled){
        setReady(true); return;
      }
      try{
        const data = await profileMe();
        if (!canceled) { setMe(data); setReady(true); }
      }catch{ if (!canceled) setReady(true); }
    })();
    return ()=>{ canceled=true; };
  },[]);

  return (
    <AppShell>
      <div className="glass card" style={{display:'grid', gap:12, maxWidth:720, margin:'0 auto'}}>
        <div className="row"><Icon name="account_circle" /><b>Профиль</b></div>

        {!isAuthed() && (
          <div className="row" style={{gap:8, flexWrap:'wrap'}}>
            <a className="btn primary" href="/login"><Icon name="login" /> Войти</a>
            <a className="btn ghost" href="/register"><Icon name="how_to_reg" /> Регистрация</a>
          </div>
        )}

        {isAuthed() && !config.flags.profileEnabled && (
          <div className="help">Профиль временно недоступен (нет /api/v1/profile/me). Функция будет включена позже.</div>
        )}

        {isAuthed() && config.flags.profileEnabled && ready && (
          <>
            <div className="row" style={{gap:12}}>
              <img src={me?.photo_url ?? config.assets.defaultAvatar} alt="avatar" style={{width:64,height:64,borderRadius:16}} />
              <div>
                <div><b>{me?.name ?? 'Без имени'}</b></div>
                <div className="help">{me?.email ?? ''}</div>
              </div>
            </div>
            <div className="sep" />
            <button className="btn ghost" onClick={()=>{ logout(); window.location.reload(); }}>
              <Icon name="logout" /> Выйти
            </button>
          </>
        )}
      </div>
    </AppShell>
  );
}
