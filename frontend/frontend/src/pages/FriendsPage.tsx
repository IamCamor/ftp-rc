import React, { useEffect, useState } from 'react';
import { friendsList, friendRequest, friendApprove, friendRemove } from '../api';

const FriendsPage: React.FC = () => {
  const [list, setList] = useState<any[]>([]);
  const [email, setEmail] = useState('');
  const [err, setErr] = useState('');

  async function reload(){
    try{
      const r = await friendsList();
      setList(Array.isArray(r)? r: []);
      setErr('');
    }catch(e:any){ setErr(e?.message||'Не удалось загрузить друзей'); }
  }
  useEffect(()=>{ reload(); },[]);

  async function sendReq(e:React.FormEvent){
    e.preventDefault();
    try{ await friendRequest(email); setEmail(''); reload(); }
    catch(e:any){ alert(e?.message||'Ошибка'); }
  }

  return (
    <div className="container">
      <h2 className="h2">Друзья</h2>
      <form className="glass card row" onSubmit={sendReq} style={{gap:8}}>
        <input className="input" placeholder="Email друга" value={email} onChange={e=>setEmail(e.target.value)} required />
        <button className="btn primary">Пригласить</button>
      </form>

      {err && <div className="card glass" style={{color:'#ffb4b4'}}>{err}</div>}

      <div className="grid" style={{marginTop:12}}>
        {list.map((f:any)=>(
          <div key={f.id} className="glass card row" style={{justifyContent:'space-between'}}>
            <div>
              <div style={{fontWeight:600}}>{f.name || f.email}</div>
              <div className="muted">{f.status || 'friend'}</div>
            </div>
            <div className="row">
              {f.request_id && f.status==='pending' && (
                <button className="btn" onClick={()=>friendApprove(f.request_id).then(reload)}>Принять</button>
              )}
              <button className="btn" onClick={()=>friendRemove(f.user_id || f.id).then(reload)}>Удалить</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
export default FriendsPage;
