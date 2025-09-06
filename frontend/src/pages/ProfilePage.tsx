import React, { useEffect, useState } from 'react';
import { profileMe } from '../api';
import config from '../config';

const ProfilePage:React.FC = () => {
  const [me, setMe] = useState<any>(null);
  const [err, setErr] = useState('');
  useEffect(() => { (async ()=>{ try { setMe(await profileMe()); } catch(e:any){ setErr(e?.message||'Ошибка'); }})(); }, []);
  return (
    <div className="container">
      <div className="glass card" style={{marginTop:16}}>
        <h2>Профиль</h2>
        {err && <div className="subtle">{err}</div>}
        {me ? (
          <div style={{display:'flex',gap:12,alignItems:'center'}}>
            <img src={me.avatar || config.brand.defaultAvatar} alt="" style={{width:72,height:72,borderRadius:16,objectFit:'cover'}}/>
            <div>
              <div style={{fontWeight:600}}>{me.name || 'Без имени'}</div>
              <div className="subtle">Бонусы: {me.bonus_balance ?? 0}</div>
            </div>
          </div>
        ) : !err && <div className="subtle">Загрузка…</div>}
      </div>
    </div>
  );
};
export default ProfilePage;
