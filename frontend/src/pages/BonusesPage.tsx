import React, { useEffect, useState } from 'react';
import { bonusBalance, bonusHistory } from '../api';
import Icon from '../components/Icon';
import config from '../config';

const BonusesPage: React.FC = () => {
  const [balance, setBalance] = useState<number>(0);
  const [list, setList] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    Promise.all([bonusBalance().catch(e=>{setErr(e.message||''); return {balance:0};}), bonusHistory().catch(()=>[])])
      .then(([b, h]: any)=> {
        setBalance(b?.balance ?? 0);
        setList(Array.isArray(h)? h: []);
      });
  },[]);

  return (
    <div className="container">
      <h2 className="h2">Бонусы</h2>
      {err && <div className="card glass" style={{color:'#ffb4b4'}}>{err}</div>}

      <div className="glass card row" style={{justifyContent:'space-between'}}>
        <div className="row"><Icon name={config.icons.gift} /> Текущий баланс</div>
        <div style={{fontWeight:700, fontSize:'1.25rem'}}>{balance}</div>
      </div>

      <h3 style={{marginTop:12}}>История</h3>
      <div className="grid">
        {list.map((i,idx)=>(
          <div key={idx} className="glass card row" style={{justifyContent:'space-between'}}>
            <div>
              <div style={{fontWeight:600}}>{i.title || i.action}</div>
              <div className="muted">{i.created_at ? new Date(i.created_at).toLocaleString(): ''}</div>
            </div>
            <div style={{fontWeight:700}}>{i.delta > 0 ? `+${i.delta}`: i.delta}</div>
          </div>
        ))}
        {list.length===0 && <div className="glass card">Записей нет</div>}
      </div>
    </div>
  );
};
export default BonusesPage;
