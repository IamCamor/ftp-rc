import React from 'react';
import config from '../config';

type Props = {
  checkedPrivacy: boolean;
  checkedOffer: boolean;
  checkedTerms: boolean;
  onChange: (p: {privacy?:boolean; offer?:boolean; terms?:boolean})=>void;
};
const LegalCheckboxes: React.FC<Props> = ({checkedPrivacy, checkedOffer, checkedTerms, onChange})=>{
  const L = config.auth.links;
  return (
    <div style={{display:'grid', gap:8, fontSize:14}}>
      <label style={{display:'flex', gap:8, alignItems:'flex-start'}}>
        <input type="checkbox" checked={checkedPrivacy} onChange={e=>onChange({privacy:e.target.checked})}/>
        <span>Соглашаюсь с <a href={L.privacy} target="_blank" rel="noreferrer">политикой обработки персональных данных</a>.</span>
      </label>
      <label style={{display:'flex', gap:8, alignItems:'flex-start'}}>
        <input type="checkbox" checked={checkedOffer} onChange={e=>onChange({offer:e.target.checked})}/>
        <span>Принимаю <a href={L.offer} target="_blank" rel="noreferrer">оферту</a>.</span>
      </label>
      <label style={{display:'flex', gap:8, alignItems:'flex-start'}}>
        <input type="checkbox" checked={checkedTerms} onChange={e=>onChange({terms:e.target.checked})}/>
        <span>Согласен с <a href={L.terms} target="_blank" rel="noreferrer">правилами пользования</a>.</span>
      </label>
    </div>
  );
};
export default LegalCheckboxes;
