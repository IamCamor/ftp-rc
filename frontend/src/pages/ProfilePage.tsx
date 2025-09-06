import React, { useEffect, useState } from 'react';
import api from '../api';

type Me = { id:number; name:string; points?:number; avatar_url?:string };

export default function ProfilePage(){
  const [me,setMe] = useState<Me|null>(null);
  const [error,setError] = useState('');

  useEffect(()=>{
    (async()=>{
      try{
        setError('');
        const res:any = await api.me();
        setMe(res);
      }catch(e:any){
        setError(e?.message||'Не удалось загрузить профиль');
      }
    })();
  },[]);

  return (
    <div className="p-3" style={{paddingBottom:80}}>
      <div className="glass card mb-3"><strong>Профиль</strong></div>
      {!!error && <div className="card" style={{color:'#ff9b9b'}}>{error}</div>}
      {!me && !error && <div className="card">Не авторизован</div>}
      {me && (
        <div className="glass card">
          <div style={{display:'flex',gap:12,alignItems:'center'}}>
            <div style={{width:64,height:64,borderRadius:'50%',background:'rgba(255,255,255,0.1)',overflow:'hidden'}}>
              {me.avatar_url && <img src={me.avatar_url} alt="" style={{width:'100%',height:'100%',objectFit:'cover'}}/>}
            </div>
            <div>
              <div style={{fontWeight:700,fontSize:18}}>{me.name}</div>
              <div style={{opacity:.7}}>Бонусы: {me.points ?? 0}</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
