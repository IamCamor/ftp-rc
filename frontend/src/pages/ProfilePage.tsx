import React,{useEffect,useState} from 'react';
import { profileMe } from '../api';
import Avatar from '../components/Avatar';

export default function ProfilePage(){
  const [me,setMe]=useState<any|null>(null);
  useEffect(()=>{ profileMe().then(setMe); },[]);
  return (
    <div className="container" style={{padding:'12px 16px 90px'}}>
      <div className="glass card" style={{display:'flex',gap:14,alignItems:'center'}}>
        <Avatar src={me?.avatar} size={56}/>
        <div>
          <div><b>{me?.name||'Гость'}</b></div>
          <div className="small">Бонусов: {me?.bonuses ?? 0}</div>
        </div>
      </div>
      <div className="grid" style={{marginTop:12}}>
        <a className="glass-card card" onClick={()=>window.navigate?.('/feed')} style={{cursor:'pointer'}}>Мои уловы</a>
        <a className="glass-card card" onClick={()=>window.navigate?.('/weather')} style={{cursor:'pointer'}}>Мои локации погоды</a>
      </div>
    </div>
  );
}
