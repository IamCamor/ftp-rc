import React, { useEffect, useState } from 'react';
import { leaderboard } from '../api';
import Icon from '../components/Icon';
import config from '../config';

const LeaderboardPage: React.FC = () => {
  const [list, setList] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    leaderboard(50).then(r=> setList(Array.isArray(r)? r: [])).catch(e=> setErr(e.message||''));
  },[]);

  return (
    <div className="container">
      <h2 className="h2">Лидерборд</h2>
      {err && <div className="glass card" style={{color:'#ffb4b4'}}>{err}</div>}

      <div className="grid">
        {list.map((u, idx)=>(
          <div key={u.user_id ?? idx} className="glass card row" style={{justifyContent:'space-between'}}>
            <div className="row">
              <Icon name={config.icons.leaderboard} />
              <strong style={{marginLeft:6}}>{u.name || `Участник #${u.user_id||idx+1}`}</strong>
            </div>
            <div className="muted">Очки: <b>{u.score ?? 0}</b></div>
          </div>
        ))}
        {list.length===0 && <div className="glass card">Нет данных</div>}
      </div>
    </div>
  );
};

export default LeaderboardPage;
