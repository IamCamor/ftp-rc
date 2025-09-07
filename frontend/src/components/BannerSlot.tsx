import React, { useEffect, useState } from 'react';
import { bannersGet } from '../api';
import config from '../config';
import Icon from './Icon';

const BannerSlot: React.FC<{slot: string}> = ({slot}) => {
  const [items, setItems] = useState<any[]>([]);
  const [err, setErr] = useState('');

  useEffect(()=>{
    bannersGet(slot)
      .then(r => setItems(Array.isArray(r)? r : []))
      .catch(e => setErr(e.message||''));
  },[slot]);

  if (err) {
    // Тихо не мешаем UX, просто ничего не показываем
    return null;
  }
  const b = items[0];
  if (!b) return null;

  return (
    <a className="glass card" href={b.click_url || config.siteBase} target="_blank" rel="noreferrer" style={{display:'flex', gap:12, alignItems:'center'}}>
      <Icon name={config.icons.ad} />
      <div style={{flex:1}}>
        <div style={{fontWeight:600}}>{b.title || 'Реклама'}</div>
        {b.text && <div className="muted">{b.text}</div>}
      </div>
      {b.image_url && <img src={b.image_url} alt="" style={{width:64, height:64, objectFit:'cover', borderRadius:8}}/>}
    </a>
  );
};

export default BannerSlot;
