import React from 'react';

type Props = {
  open: boolean;
  title?: string;
  text?: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm: ()=>void;
  onCancel: ()=>void;
};
const Confirm: React.FC<Props> = ({open, title='Подтверждение', text='Вы уверены?', confirmText='ОК', cancelText='Отмена', onConfirm, onCancel})=>{
  if(!open) return null;
  return (
    <div style={{position:'fixed', inset:0, background:'rgba(0,0,0,.35)', display:'grid', placeItems:'center', zIndex:10000}}>
      <div className="glass card" style={{minWidth:320, maxWidth:520}}>
        <div className="h3" style={{marginBottom:8}}>{title}</div>
        <div className="muted" style={{marginBottom:12}}>{text}</div>
        <div className="row" style={{justifyContent:'flex-end', gap:8}}>
          <button className="btn" onClick={onCancel}>{cancelText}</button>
          <button className="btn primary" onClick={onConfirm}>{confirmText}</button>
        </div>
      </div>
    </div>
  );
};
export default Confirm;
