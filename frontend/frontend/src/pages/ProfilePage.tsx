import React, { useEffect, useState } from 'react';
import config from '../config';
import { profileMe, isAuthed, logout } from '../api';
import { Link } from 'react-router-dom';
import Icon from '../components/Icon';

const ProfilePage: React.FC = () => {
  const [me, setMe] = useState<any>(null);
  const [err, setErr] = useState<string>('');

  useEffect(() => {
    if (!isAuthed()) {
      setErr('Требуется вход в систему.');
      return;
    }
    profileMe()
      .then(setMe)
      .catch((e) => setErr(e.message || 'Не удалось загрузить профиль'));
  }, []);

  const avatar = me?.photo_url || config?.images?.defaultAvatar || '/assets/default-avatar.png';

  return (
    <div className="container">
      <div className="glass card" style={{display:'flex', gap:12, alignItems:'center'}}>
        <img src={avatar} alt="avatar" style={{width:64, height:64, borderRadius:'50%', objectFit:'cover'}} />
        <div style={{flex:1}}>
          <div style={{fontWeight:600}}>{me?.name || '—'}</div>
          <div className="muted">{me?.email || ''}</div>
        </div>
        {isAuthed() && (
          <button className="btn" onClick={()=>{ logout(); location.href='/login'; }}>Выйти</button>
        )}
      </div>
      {err && <div className="card glass" style={{color:'#ffb4b4', marginTop:10}}>{err}</div>}

      <div className="grid" style={{marginTop:12}}>
        <Link to="/friends" className="glass card row" style={{justifyContent:'space-between'}}>
          <div className="row"><Icon name={config.icons.friends} /> Друзья</div>
          <Icon name="chevron_right" />
        </Link>
        <Link to="/bonuses" className="glass card row" style={{justifyContent:'space-between'}}>
          <div className="row"><Icon name={config.icons.gift} /> Бонусы и история</div>
          <Icon name="chevron_right" />
        </Link>
        <Link to="/leaderboard" className="glass card row" style={{justifyContent:'space-between'}}>
          <div className="row"><Icon name={config.icons.leaderboard} /> Лидерборд</div>
          <Icon name="chevron_right" />
        </Link>
        <Link to="/settings" className="glass card row" style={{justifyContent:'space-between'}}>
          <div className="row"><Icon name={config.icons.settings} /> Настройки профиля</div>
          <Icon name="chevron_right" />
        </Link>
      </div>
    </div>
  );
};

export default ProfilePage;
