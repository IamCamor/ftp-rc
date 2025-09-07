import React, { useEffect, useState } from 'react';
import { settingsGet, settingsUpdate } from '../api';

const SettingsPage: React.FC = () => {
  const [data, setData] = useState<any>({});
  const [msg, setMsg] = useState('');

  useEffect(()=>{
    settingsGet().then(setData).catch(()=>setData({}));
  },[]);

  function set<K extends string>(k:K, v:any){ setData((s:any)=> ({...s, [k]:v})); }

  async function save(e:React.FormEvent){
    e.preventDefault(); setMsg('');
    try{
      await settingsUpdate(data);
      setMsg('Сохранено');
    }catch(e:any){ setMsg(e?.message||'Ошибка'); }
  }

  return (
    <div className="container">
      <h2 className="h2">Настройки профиля</h2>
      <form className="glass card grid" onSubmit={save}>
        <label>Никнейм</label>
        <input className="input" value={data.nickname||''} onChange={e=>set('nickname', e.target.value)} />
        <label>Приватность по умолчанию</label>
        <select className="select" value={data.default_privacy||'all'} onChange={e=>set('default_privacy', e.target.value)}>
          <option value="all">Все</option>
          <option value="friends">Друзья</option>
          <option value="private">Лично</option>
        </select>
        <button className="btn primary" type="submit">Сохранить</button>
        {msg && <div className="muted">{msg}</div>}
      </form>
    </div>
  );
};
export default SettingsPage;
